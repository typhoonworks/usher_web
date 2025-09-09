defmodule Usher.Web.Pages.InvitationsListPage do
  use Usher.Web, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <div class="md:flex md:items-center md:justify-between">
        <div class="min-w-0 flex-1">
          <h2 class="text-2xl/7 font-bold text-zinc-900 dark:text-zinc-200 sm:truncate sm:text-3xl sm:tracking-tight">
            Invitations
          </h2>
          <p class="mt-1 text-sm text-zinc-600 dark:text-zinc-400">
            View and manage invitations.
          </p>
        </div>
        <div class="mt-4 flex md:ml-4 md:mt-0">
          <%!-- <.link navigate={~p"/admin/invitations/new"}>
            <.button>
              <.icon name="hero-plus" class="size-5 mr-1" /> New Invitation
            </.button>
          </.link> --%>
        </div>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-md overflow-x-auto">
        <.table id="invitations" rows={@streams.invitations}>
          <:col :let={{_id, invitation}} label="Name">
            <span class="text-sm font-bold text-zinc-900 dark:text-zinc-200">
              {invitation.name || "Unnamed"}
            </span>
          </:col>
          <:col :let={{_id, invitation}} label="Created">
            <time class="text-sm text-zinc-900 dark:text-zinc-200">
              {Calendar.strftime(invitation.inserted_at, "%b %d, %Y")}
            </time>
          </:col>
          <:col :let={{_id, invitation}} label="Expires">
            <span class={[
              "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
              expires_at_class(invitation)
            ]}>
              {expires_at(invitation)}
            </span>
          </:col>
          <:col :let={{_id, invitation}} label="Usage">
            <div class="flex items-center space-x-2">
              <span class="text-sm font-medium text-zinc-900 dark:text-zinc-200">
                {invitation.joined_count}
              </span>
              <span class="text-sm text-zinc-900 dark:text-zinc-200">
                {if invitation.joined_count == 1, do: "user", else: "users"}
              </span>
            </div>
          </:col>
          <:col :let={{id, invitation}} label="Invitation Link">
            <div class="flex items-center space-x-2">
              <.link
                class="text-blue-600 hover:text-blue-800 text-sm font-mono truncate max-w-xs"
                href={token_link(invitation)}
                target="_blank"
              >
                {token_link_display_value(token_link(invitation))}
              </.link>
              <.button
                id={"copy-invitation-token-link-#{id}"}
                variant="light"
                class="text-zinc-700 bg-zinc-100 hover:bg-zinc-200 px-2 py-1"
                phx-hook="Clipboard"
                data-clipboard-text={token_link(invitation)}
                title="Copy invitation link"
              >
                <.icon name="hero-clipboard" class="h-4 w-4" />
              </.button>
            </div>
          </:col>
          <:action :let={{_id, invitation}}>
            <div class="flex items-center justify-end space-x-2 pr-4">
              <%!-- <.link patch={~p"/admin/invitations/#{invitation.id}/edit"}>
                <.button
                  variant="light"
                  class="text-blue-700 bg-blue-100 hover:bg-blue-200 px-3 py-2"
                  title="Edit invitation"
                >
                  <.icon name="hero-pencil" class="h-4 w-4" />
                </.button>
              </.link> --%>
              <.button
                variant="light"
                class="text-red-700 bg-red-100 hover:bg-red-200 px-3 py-2"
                phx-click="delete_invitation"
                phx-value-id={invitation.id}
                title="Delete invitation"
              >
                <.icon name="hero-trash" class="h-4 w-4" />
              </.button>
            </div>
          </:action>
        </.table>
      </div>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="invitation-modal"
        show
      >
        <%!-- on_cancel={JS.patch(~p"/admin/invitations")} --%>
        <.live_component
          module={AccomplishWeb.InvitationLive.FormComponent}
          id={@invitation.id || :new}
          title={if @live_action == :new, do: "New Invitation", else: "Edit Invitation"}
          action={@live_action}
          invitation={@invitation}
          timezone={@timezone}
        />
        <%!-- patch={~p"/admin/invitations"} --%>
      </.modal>

      <.modal
        :if={@delete_confirmation}
        id="delete-confirmation-modal"
        show={true}
        on_cancel={JS.push("cancel_delete_invitation")}
      >
        <div class="space-y-4">
          <h3 class="text-lg font-medium text-zinc-900">Confirm Deletion</h3>
          <p class="text-zinc-700">
            Are you sure you want to delete this invitation?
            This action cannot be undone and will invalidate the invitation link.
          </p>
          <div class="flex justify-end space-x-3 mt-5">
            <.button type="button" variant="light" phx-click="cancel_delete_invitation">
              Cancel
            </.button>
            <.button
              type="button"
              variant="danger"
              phx-click="confirm_delete_invitation"
              phx-value-id={@delete_confirmation.id}
            >
              <.icon name="hero-trash" class="h-4 w-4 mr-1" /> Delete
            </.button>
          </div>
        </div>
      </.modal>
    </div>
    """
  end

  def handle_mount(socket) do
    invitations =
      Usher.list_invitations()
      |> Enum.map(&add_usage_count/1)

    socket
    |> assign(:delete_confirmation, nil)
    |> stream(:invitations, invitations)
  end

  defp token_link(invitation) do
    # signup_url = app_url("signup")
    Usher.invitation_url(invitation.token, "http://localhost:4000")
  end

  defp token_link_display_value(link) do
    String.slice(link, -1 * Usher.Config.token_length(), 20)
  end

  defp expires_at(%{expires_at: expires_at}) when is_struct(expires_at, DateTime) do
    DateTimeHelpers.time_left_until(expires_at)
  end

  defp expires_at(_), do: "Never"

  defp expires_at_class(invitation) do
    cond do
      is_nil(invitation.expires_at) ->
        "bg-green-100 text-green-800"

      DateTime.compare(invitation.expires_at, DateTime.utc_now()) == :lt ->
        "bg-red-100 text-red-800"

      DateTime.diff(invitation.expires_at, DateTime.utc_now(), :day) <= 7 ->
        "bg-yellow-100 text-yellow-800"

      true ->
        "bg-blue-100 text-blue-800"
    end
  end

  defp add_usage_count(invitation) do
    # Get unique users that registered using this invitation
    unique_registrations =
      Usher.list_invitation_usages_by_unique_entity(
        invitation,
        entity_type: :user,
        action: :registered
      )

    # Add joined_count as a virtual field for backward compatibility
    Map.put(invitation, :joined_count, length(unique_registrations))
  end
end
