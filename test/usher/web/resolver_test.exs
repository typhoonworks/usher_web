defmodule Usher.Web.ResolverTest do
  use Usher.Web.ConnCase, async: true

  alias Usher.Web.Router

  defmodule TestResolver do
    @behaviour Usher.Web.Resolver

    @impl true
    def resolve_user(conn) do
      conn.private.current_user
    end

    @impl true
    def resolve_access(user) do
      if user.admin? do
        :all
      else
        :read_only
      end
    end
  end

  test "resolver is called", %{conn: conn} do
    conn = Plug.Conn.put_private(conn, :current_user, %{id: 1, admin?: true})

    session = options_to_session(conn, resolver: TestResolver)

    assert session["user"] == %{id: 1, admin?: true}
    assert session["access"] == :all
    assert session["resolver"] == TestResolver
  end

  test "session gets default resolver when none provided", %{conn: conn} do
    session = options_to_session(conn, [])

    assert session["user"] == nil
    assert session["access"] == :all
    assert session["resolver"] == Usher.Web.Resolver
  end

  defp options_to_session(conn, opts) do
    {_name, session_opts, _opts} = Router.__options__("/usher", opts)

    {Router, :__session__, session_opts} = Keyword.get(session_opts, :session)

    apply(Router, :__session__, [conn | session_opts])
  end
end
