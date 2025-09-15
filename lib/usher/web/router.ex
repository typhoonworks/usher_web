defmodule Usher.Web.Router do
  @moduledoc """
  Mount the Usher Dashboard into a Phoenix router.

  This module provides the `usher_dashboard/2` macro, which mounts Usher's
  LiveView-powered dashboard and wires it to your application's LiveView socket.

  ## Usage

  Import `Usher.Web.Router` in your Phoenix router and call `usher_dashboard/2`
  within a scope that uses your browser pipeline:

      defmodule MyAppWeb.Router do
        use MyAppWeb, :router

        import Usher.Web.Router

        pipeline :browser do
          plug :accepts, ["html"]
          plug :fetch_session
          plug :fetch_live_flash
          plug :put_root_layout, {MyAppWeb.Layouts, :root}
          plug :protect_from_forgery
          plug :put_secure_browser_headers
          # ...your auth plug(s) that assign the current user...
        end

        scope "/" do
          pipe_through :browser

          # Mount at "/usher" with default options
          usher_dashboard "/usher"
        end
      end

  By default, this mounts three routes under the given path:

  - `GET /usher` — Dashboard index
  - `GET /usher/new` — New item view
  - `GET /usher/:id/edit` — Edit item view

  The exact UI and behavior are provided by Usher's LiveViews and may evolve,
  but the route structure remains stable for helpers and links.

  ## Important

  Usher does not implement authentication on its own. Until you configure an
  authentication pipeline and a custom resolver (`resolver:` option), the
  default `Usher.Web.Resolver` allows access for everyone (`:all`). Protect your
  Usher routes behind your browser/auth pipelines and provide a resolver to
  restrict access appropriately. See `Usher.Web.Authentication` and
  `Usher.Web.Resolver` for details.

  ## Options

  - `:as` — Prefix used for route helpers and the LiveView session name.
    Defaults to `:usher_dashboard`. For example, with the default you can
    generate paths with `~p"/usher"` or via helpers such as
    `Routes.usher_dashboard_path(conn, :index)` depending on your Phoenix
    version and setup.

  - `:socket_path` — Path to your LiveView socket. Defaults to `"/live"`.
    Change this if your application configured a custom LiveView socket path.

  - `:transport` — LiveView transport, either `:websocket` (default) or
    `:longpoll`. Match this to your LiveView configuration.

  - `:csp_nonce_assign_key` — Configure how CSP nonces are read from
    `conn.assigns` and injected into the LiveView session. Accepts:
      * `nil` (default): no CSP nonces are propagated
      * an atom: the same assign key is used for both script and style nonces
      * a map: `%{script: :script_key, style: :style_key}` for independent keys

    For Phoenix apps that place a single nonce under `:csp_nonce`, you can pass
    `csp_nonce_assign_key: :csp_nonce`. If you maintain separate keys, pass
    a map such as `csp_nonce_assign_key: %{script: :csp_script_nonce, style: :csp_style_nonce}`.

  - `:resolver` — A module that implements the `Usher.Web.Resolver` behaviour
    used to determine the current user and their access level. Defaults to
    `Usher.Web.Resolver`, which allows all access. See `Usher.Web.Authentication`
    for end-to-end authentication and access control details.

  - `:on_mount` — A list of additional `on_mount` hooks to run for all Usher
    LiveViews. Usher always prepends `Usher.Web.Authentication` and
    Usher.Web.LiveMount; any hooks you provide are invoked afterwards.

  ## Authentication & access control

  Usher's dashboard authentication flow is implemented by the
  `Usher.Web.Authentication` on-mount hook together with a configurable
  `Usher.Web.Resolver`. The resolver extracts a user and determines an access
  level; the hook applies enforcement (including redirects for forbidden
  access). See `Usher.Web.Authentication` for the complete walkthrough and a
  resolver example.

  ## CSP Nonces

  If your application enforces a strict CSP and uses per-request nonces, set
  `:csp_nonce_assign_key` so Usher's LiveViews receive and apply the nonces to
  inline scripts and styles as needed. Usher reads the nonces from
  `conn.assigns` using the keys you provide and makes them available as
  `@csp_nonces.script` and `@csp_nonces.style` assigns during mount.

  ## Session Data

  Usher stores a small set of values in the LiveView session for each request,
  all of which are internal implementation details. They are documented here to
  aid integration and debugging:

  - `"prefix"` — the mounted path prefix (scope-aware)
  - `"live_path"` — the LiveView socket path (e.g., `"/live"`)
  - `"live_transport"` — the chosen LiveView transport
  - `"resolver"` — the resolver module used for auth/access
  - `"user"` — the resolved user value
  - `"access"` — the access level derived by the resolver
  - `"csp_nonces"` — a map with `:script` and `:style` nonce values (when set)
  """

  import Phoenix.Component, only: [assign: 2, assign: 3]

  alias Usher.Web.Resolver

  @default_opts [
    socket_path: "/live",
    transport: :websocket,
    csp_nonce_assign_key: nil,
    resolver: Usher.Web.Resolver
  ]

  @allowed_transport_values ~w(longpoll websocket)a

  @doc """
  Mount the Usher Dashboard at the given `path` within a Phoenix router.

  See the module documentation for a complete list of options and usage notes.
  """
  defmacro usher_dashboard(path, opts \\ []) do
    quote bind_quoted: binding() do
      prefix = Phoenix.Router.scoped_path(__MODULE__, path)

      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 4, live_session: 3]

        {session_name, session_opts, route_opts} = Usher.Web.Router.__options__(prefix, opts)

        live_session session_name, session_opts do
          live "/", Usher.Web.Live.InvitationsList, :index, route_opts
          live "/new", Usher.Web.Live.InvitationsList, :new, route_opts
          live "/:id/edit", Usher.Web.Live.InvitationsList, :edit, route_opts
        end
      end
    end
  end

  def __options__(prefix, opts) do
    opts = Keyword.merge(@default_opts, opts)

    Enum.each(opts, &validate_opt!/1)

    on_mount = Keyword.get(opts, :on_mount, [])
    on_mount = [Usher.Web.Authentication, Usher.Web.LiveMount | on_mount]

    session_args = [
      prefix,
      opts[:socket_path],
      opts[:transport],
      opts[:csp_nonce_assign_key],
      opts[:resolver]
    ]

    session_opts = [
      on_mount: on_mount,
      session: {__MODULE__, :__session__, session_args},
      root_layout: {Usher.Web.Layouts, :root}
    ]

    session_name = Keyword.get(opts, :as, :usher_dashboard)

    {session_name, session_opts, as: session_name}
  end

  def __session__(conn, prefix, live_path, live_transport, csp_key, resolver) do
    csp_keys = expand_csp_nonce_keys(csp_key)

    user = Resolver.call_with_fallback(resolver, :resolve_user, [conn])
    access = Resolver.call_with_fallback(resolver, :resolve_access, [user])

    %{
      "prefix" => prefix,
      "live_path" => live_path,
      "live_transport" => live_transport,
      "resolver" => resolver,
      "user" => user,
      "access" => access,
      "csp_nonces" => %{
        style: conn.assigns[csp_keys[:style]],
        script: conn.assigns[csp_keys[:script]]
      }
    }
  end

  def on_mount(:usher_on_mount_hook, _params, session, socket) do
    %{
      "prefix" => prefix,
      "live_path" => live_path,
      "live_transport" => live_transport,
      "csp_nonces" => csp_nonces,
      "resolver" => resolver,
      "user" => user,
      "access" => access
    } = session

    Process.put(:routing, {socket, prefix})

    socket =
      socket
      |> assign(live_path: live_path, live_transport: live_transport)
      |> assign(:page_title, "Usher Dashboard")
      |> assign(:csp_nonces, csp_nonces)
      |> assign(:resolver, resolver)
      |> assign(user: user, access: access)

    {:cont, socket}
  end

  defp expand_csp_nonce_keys(nil), do: %{style: nil, script: nil}
  defp expand_csp_nonce_keys(key) when is_atom(key), do: %{style: key, script: key}
  defp expand_csp_nonce_keys(map) when is_map(map), do: map

  defp validate_opt!({:socket_path, path}) do
    unless is_binary(path) and byte_size(path) > 0 do
      raise ArgumentError, """
      invalid :socket_path, expected a binary URL, got: #{inspect(path)}
      """
    end
  end

  defp validate_opt!({:transport, transport}) do
    unless transport in @allowed_transport_values do
      raise ArgumentError, """
      invalid :transport, expected one of #{inspect(@allowed_transport_values)},
      got #{inspect(transport)}
      """
    end
  end

  defp validate_opt!({:csp_nonce_assign_key, key}) do
    unless is_nil(key) or is_atom(key) or is_map(key) do
      raise ArgumentError, """
      invalid :csp_nonce_assign_key, expected nil, an atom or a map with atom keys,
      got #{inspect(key)}
      """
    end
  end

  defp validate_opt!({:resolver, resolver}) do
    unless is_atom(resolver) and not is_nil(resolver) do
      raise ArgumentError, """
      invalid :resolver, expected a module that implements the Usher.Web.Resolver behaviour,
      got: #{inspect(resolver)}
      """
    end
  end

  defp validate_opt!(invalid_opt) do
    raise ArgumentError, "invalid option for usher_web: #{inspect(invalid_opt)}"
  end
end
