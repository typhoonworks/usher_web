defmodule Usher.Web.Helpers.PathHelpersTest do
  use Usher.Web.ConnCase, async: true

  alias Phoenix.LiveViewTest

  alias Usher.Web.Helpers.PathHelpers

  defmodule SocketProbeLive do
    @moduledoc """
    Module for probing the socket for path helper tests.
    """

    use Phoenix.LiveView

    @impl true
    def mount(_params, _session, socket) do
      {:ok, socket}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div id="probe">ok</div>
      """
    end

    @impl true
    def handle_info({:send_socket, pid}, socket) do
      send(pid, {:socket, socket})

      {:noreply, socket}
    end
  end

  describe "usher_path/0 (when no path is passed)" do
    test "returns root path when routing is set to :nowhere" do
      Process.put(:routing, :nowhere)

      assert PathHelpers.usher_path() == "/"
    end

    test "constructs base path with socket and prefix from process dictionary", %{conn: conn} do
      socket = mounted_socket(conn)
      prefix = "/usher"
      Process.put(:routing, {socket, prefix})

      path = PathHelpers.usher_path()
      assert prefix <> "/" == path
    end

    test "raises error when no routing is set in process dictionary" do
      assert_raise RuntimeError, "nothing stored in the :rounting key", fn ->
        PathHelpers.usher_path()
      end
    end
  end

  describe "usher_path/2 with string route" do
    test "returns root path when routing is set to :nowhere" do
      Process.put(:routing, :nowhere)

      assert PathHelpers.usher_path("/users", %{}) == "/"
      assert PathHelpers.usher_path("/settings", %{id: 1}) == "/"
    end

    test "constructs base path socket and prefix from process dictionary", %{conn: conn} do
      socket = mounted_socket(conn)
      prefix = "/usher"
      Process.put(:routing, {socket, prefix})

      path = PathHelpers.usher_path("/users", %{})
      assert prefix <> "/users" == path
    end

    test "handles route parameters", %{conn: conn} do
      socket = mounted_socket(conn)
      prefix = "/usher"
      Process.put(:routing, {socket, prefix})

      path = PathHelpers.usher_path("/users", %{page: 1, filter: "active"})
      assert prefix <> "/users?filter=active&page=1" == path
    end

    test "raises error when no routing is set in process dictionary" do
      assert_raise RuntimeError, "nothing stored in the :rounting key", fn ->
        PathHelpers.usher_path("/users", %{})
      end
    end
  end

  describe "usher_path/2 with list route" do
    test "converts list route to string path" do
      Process.put(:routing, :nowhere)

      assert PathHelpers.usher_path(["users", "profile"], %{}) == "/"
    end

    test "constructs path from list with socket and prefix", %{conn: conn} do
      socket = mounted_socket(conn)
      prefix = "/usher"
      Process.put(:routing, {socket, prefix})

      path = PathHelpers.usher_path(["users", "123", "edit"], %{})
      assert prefix <> "/users/123/edit" == path
    end

    test "handles empty list route" do
      Process.put(:routing, :nowhere)

      assert PathHelpers.usher_path([], %{}) == "/"
    end

    test "handles single item list route", %{conn: conn} do
      socket = mounted_socket(conn)
      prefix = "/usher"
      Process.put(:routing, {socket, prefix})

      path = PathHelpers.usher_path(["dashboard"], %{})
      assert prefix <> "/dashboard" == path
    end

    test "raises error when no routing is set in process dictionary with list route" do
      assert_raise RuntimeError, "nothing stored in the :rounting key", fn ->
        PathHelpers.usher_path(["users", "profile"], %{})
      end
    end
  end

  describe "path construction with different prefixes" do
    test "handles url as prefix", %{conn: conn} do
      socket = mounted_socket(conn)
      prefix = "http://localhost:4000/admin"
      Process.put(:routing, {socket, prefix})

      url = PathHelpers.usher_path("/dashboard", %{})
      assert prefix <> "/dashboard" == url
    end
  end

  defp mounted_socket(conn) do
    {:ok, view, _html} = LiveViewTest.live_isolated(conn, __MODULE__.SocketProbeLive)
    send(view.pid, {:send_socket, self()})
    assert_receive {:socket, socket}

    %Phoenix.LiveView.Socket{socket | router: Usher.Web.TestRouter}
  end
end
