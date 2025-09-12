defmodule Usher.Web.Router do
  @moduledoc false

  @default_opts [
    socket_path: "/live",
    transport: :websocket,
    csp_nonce_assign_key: nil,
    resolver: Usher.Web.Resolver
  ]

  @allowed_transport_values ~w(longpoll websocket)a

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

    user = Usher.Web.Resolver.call_with_fallback(resolver, :resolve_user, [conn])
    access = Usher.Web.Resolver.call_with_fallback(resolver, :resolve_access, [user])

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
      |> Phoenix.Component.assign(live_path: live_path, live_transport: live_transport)
      |> Phoenix.Component.assign(:page_title, "Usher Dashboard")
      |> Phoenix.Component.assign(:csp_nonces, csp_nonces)
      |> Phoenix.Component.assign(:resolver, resolver)
      |> Phoenix.Component.assign(user: user, access: access)

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
