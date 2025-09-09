defmodule Usher.Web.DashboardLive do
  use Usher.Web, :live_view

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    %{
      "live_path" => live_path,
      "live_transport" => live_transport,
      "csp_nonces" => csp_nonces,
      "resolver" => resolver
    } = session

    socket =
      socket
      |> assign(live_path: live_path, live_transport: live_transport)
      |> assign(:page_title, "Usher Dashboard")
      |> assign(:csp_nonces, csp_nonces)
      |> assign(:resolver, resolver)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <h1>Dashboard</h1>
      <p>Welcome to the dashboard!</p>
    </div>
    """
  end
end
