defmodule Usher.Web.Router do
  @moduledoc false

  @default_opts [
    socket_path: "/live",
    transport: :websocket,
    csp_nonce_assign_key: nil,
    resolver: Usher.Web.Resolver
  ]

  defmacro usher_dashboard(path, opts \\ []) do
    quote bind_quoted: binding() do
      prefix = Phoenix.Router.scoped_path(__MODULE__, path)

      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 4, live_session: 3]

        {session_name, session_opts, route_opts} = Usher.Web.Router.__options__(prefix, opts)

        live_session session_name, session_opts do
          live "/", Usher.Web.DashboardLive, :index, route_opts
          live "/new", Usher.Web.DashboardLive, :new, route_opts
          live "/:id", Usher.Web.DashboardLive, :show, route_opts
        end
      end
    end
  end

  def __options__(prefix, opts) do
    opts = Keyword.merge(@default_opts, opts)

    Enum.each(opts, &validate_opt!/1)

    on_mount = Keyword.get(opts, :on_mount, [])

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

  defp expand_csp_nonce_keys(nil), do: %{style: nil, script: nil}
  defp expand_csp_nonce_keys(key) when is_atom(key), do: %{style: key, script: key}
  defp expand_csp_nonce_keys(map) when is_map(map), do: map

  defp validate_opt!(_option), do: :ok
end
