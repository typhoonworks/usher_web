defmodule Usher.Web.Resolver do
  @moduledoc """
  Behaviour module for resolving users and access levels for the Usher Dashboard.

  A resolver is responsible for two things:

  - Extracting the current user from a `Plug.Conn` when the dashboard mounts
  - Mapping that user to an access level for the dashboard

  Usher invokes your resolver from the router to populate the LiveView session.
  Enforcement happens in `Usher.Web.Authentication`, which reads the session and
  halts/redirects when access is forbidden. See `Usher.Web.Router` for mounting
  and configuration, and `Usher.Web.Authentication` for the on-mount hook.

  ## Callbacks

  - `c:resolve_user/1` — Given a `Plug.Conn`, return a user value (map/struct) or
    `nil`. This value is passed to `c:resolve_access/1`.
  - `c:resolve_access/1` — Given the user value, return one of the supported
    access levels:

    - `:all` — Full access
    - `:read_only` — View-only access, with mutations disabled
    - `:forbidden` — No access; authentication will redirect to `/`
    - `{:forbidden, path}` — No access; redirect to the given path

  Both callbacks are optional. If a callback isn’t implemented, Usher falls
  back to the defaults defined in this module: `resolve_user/1` returns `nil`
  and `resolve_access/1` returns `:all`.

  ## Security note

  You are expected to implement these callbacks to enforce your application's
  authentication and authorization policies. If you don't, the defaults mean
  anyone can access the Usher UI (no authentication, full access). Pair this
  with a proper authentication pipeline and pass your resolver via the router
  option `resolver:`.

  ## Example

      defmodule MyAppWeb.UsherResolver do
        @behaviour Usher.Web.Resolver

        # Pull the current user from assigns (your auth plug should set this)
        def resolve_user(conn), do: conn.assigns[:current_user]

        # Map user roles to access levels
        def resolve_access(%{role: :admin}), do: :all
        def resolve_access(%{role: :viewer}), do: :read_only
        def resolve_access(_), do: :forbidden
      end

  Then configure the dashboard to use your resolver in your Phoenix router:

      import Usher.Web.Router
      scope "/" do
        pipe_through :browser
        usher_dashboard "/usher", resolver: MyAppWeb.UsherResolver
      end

  See `Usher.Web.Authentication` for how the access level is enforced during
  LiveView mount.
  """

  @type user :: nil | map() | struct()

  @type access_level ::
          :all
          | :read_only
          | :forbidden
          | {:forbidden, String.t()}

  @doc """
  Extract the current user from a Plug.Conn when the dashboard mounts.

  This callback is invoked when the Usher dashboard is accessed. The returned
  user value will be passed to other callbacks for access control decisions.
  """
  @callback resolve_user(conn :: Plug.Conn.t()) :: user()

  @doc """
  Determine the access level for a user.

  Based on the user returned from `resolve_user/1`, this callback determines
  what operations the user can perform in the Usher dashboard.

  ## Return Values

  - `:all` - Full access to all Usher's features
  - `:read_only` - Can only view and run queries, no modifications
  - `:forbidden` - No access
  - `{:forbidden, path}` - Redirect to the given path
  """
  @callback resolve_access(user :: user()) :: access_level()

  @optional_callbacks resolve_user: 1, resolve_access: 1

  @doc false
  def call_with_fallback(resolver, fun, args) when is_atom(fun) and is_list(args) do
    resolver = if function_exported?(resolver, fun, length(args)), do: resolver, else: __MODULE__

    apply(resolver, fun, args)
  end

  @doc false
  def resolve_user(_conn), do: nil

  @doc false
  def resolve_access(_user), do: :all
end
