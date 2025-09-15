defmodule Usher.Web.Authentication do
  @moduledoc """
  LiveView `on_mount` hook for Usher's authentication and access control.

  This module enforces access to the Usher Dashboard by reading values placed
  in the LiveView session by `Usher.Web.Router`. It doesn't perform user lookup
  itself; instead, it relies on a configured resolver implementing the
  `Usher.Web.Resolver` behaviour.

  ## How it works

  When the Usher Dashboard mounts, the router injects session data including a
  `"resolver"`, a `"user"`, and an `"access"` level. This hook assigns those to
  the socket and halts navigation if access is forbidden:

  - `:all` — full access
  - `:read_only` — limited, view-only access (UI elements may restrict actions)
  - `:forbidden` — denies access and navigates to `/` with a flash message
  - `{:forbidden, path}` — denies access and navigates to `path` with a flash

  The final enforcement is handled here, while determination of the user and
  access level is delegated to the resolver.

  ## Resolver behaviour

  The resolver is responsible for extracting the user from `Plug.Conn` and
  mapping that user to an access level. See `Usher.Web.Resolver` for the
  behaviour and return values. A typical resolver may look like this:

      defmodule MyAppWeb.UsherResolver do
        @behaviour Usher.Web.Resolver

        def resolve_user(conn), do: conn.assigns[:current_user]

        def resolve_access(%{role: :admin}), do: :all
        def resolve_access(%{role: :viewer}), do: :read_only
        def resolve_access(_), do: :forbidden
      end

  Configure the dashboard to use your resolver:

      import Usher.Web.Router
      scope "/" do
        pipe_through :browser
        usher_dashboard "/usher", resolver: MyAppWeb.UsherResolver
      end

  ## Integration notes

  - Protect the Usher routes behind your existing authentication pipeline.
  - Prefer placing the current user into `conn.assigns` in your auth plug(s) so
    your resolver can read it easily.
  - For apps with role-based access, return `:read_only` for non-admins to
    allow safe observation without modification.

  ## Important

  Usher does not provide authentication for you. You must:

  - Implement your own authentication pipeline (plugs) to sign users in and set
    a user into `conn.assigns`.
  - Provide a resolver module via the router option `resolver:` to determine the
    appropriate access level for each user.

  If you don't provide a resolver, the default `Usher.Web.Resolver` allows
  access for everyone (`resolve_access/1` defaults to `:all`). That means the
  dashboard is open to any visitor of the mounted routes until you configure
  authentication and a resolver.

  See `Usher.Web.Router` for mounting and configuration options.
  """

  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:default, _params, session, socket) do
    %{"resolver" => resolver, "user" => user} = session
    access = Map.get(session, "access", :all)

    socket = assign(socket, resolver: resolver, user: user, access: access)

    case access do
      {:forbidden, path} ->
        socket =
          socket
          |> put_flash(:error, "Access forbidden")
          |> push_navigate(to: path)

        {:halt, socket}

      :forbidden ->
        socket =
          socket
          |> put_flash(:error, "Access forbidden")
          |> push_navigate(to: "/")

        {:halt, socket}

      _ ->
        {:cont, socket}
    end
  end
end
