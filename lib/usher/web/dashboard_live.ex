defmodule Usher.Web.DashboardLive do
  use Usher.Web, :live_view

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    %{
      "prefix" => prefix,
      "live_path" => live_path,
      "live_transport" => live_transport,
      "csp_nonces" => csp_nonces,
      "resolver" => resolver
    } = session

    page = resolve_page(params)

    Process.put(:routing, {socket, prefix})

    socket =
      socket
      |> assign(page: page)
      |> assign(live_path: live_path, live_transport: live_transport)
      |> assign(:page_title, "Usher Dashboard")
      |> assign(:csp_nonces, csp_nonces)
      |> assign(:resolver, resolver)
      |> page.component.handle_mount()

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.live_component id="page" module={@page.component} {assigns} />
    """
  end

  defp resolve_page(%{"page" => "invitations"}),
    do: %{name: :invitations, component: Usher.Web.Pages.InvitationsListPage}

  defp resolve_page(_), do: resolve_page(%{"page" => "invitations"})
end
