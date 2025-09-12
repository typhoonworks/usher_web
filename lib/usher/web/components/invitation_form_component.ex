defmodule Usher.Web.Components.InvitationFormComponent do
  use Usher.Web, :live_component

  alias Usher.Invitation

  defmodule InvitationFormData do
    use Ecto.Schema

    import Ecto.Changeset

    embedded_schema do
      field(:name, :string)
      field(:token, :string)
      field(:set_expiration, :boolean, default: false)
      field(:expires_on, :date)
    end

    def create_changeset(%Invitation{} = invitation) do
      expires_on =
        if invitation.expires_at do
          DateTime.to_date(invitation.expires_at)
        else
          nil
        end

      attrs =
        invitation
        |> Map.from_struct()
        |> Map.take([:name, :token])
        |> Map.put(:set_expiration, not is_nil(invitation.expires_at))
        |> Map.put(:expires_on, expires_on)

      %__MODULE__{}
      |> cast(attrs, [:name, :token, :expires_on, :set_expiration])
    end

    def update_changeset(struct, attrs) do
      struct
      |> cast(attrs, [:name, :token, :expires_on, :set_expiration])
      |> validate_required([:name])
      |> maybe_clear_expires_on()
    end

    defp maybe_clear_expires_on(changeset) do
      case get_field(changeset, :set_expiration) do
        true ->
          validate_required(changeset, [:expires_on])

        false ->
          put_change(changeset, :expires_on, nil)
      end
    end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        :let={f}
        as="invitation"
        id="invitation-form"
        for={@form}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        phx-hook="GetUserTimezone"
      >
        <div class="space-y-4">
          <h2 class="text-lg font-semibold leading-6 text-zinc-900">
            {@title}
          </h2>

          <div>
            <.input
              field={f[:name]}
              type="text"
              label="Name"
              placeholder="Enter invitation name"
              required
            />
          </div>

          <div>
            <%!-- <input type="hidden" name={f[:token].name} value={f[:token].value} /> --%>
            <div class="space-y-1">
              <label class="block text-sm font-bold text-gray-700">Token</label>
              <p :if={@action == :new} class="text-sm text-gray-500">
                A unique token will be automatically generated for this invitation
              </p>
              <p
                :if={@action == :edit}
                class="text-sm text-gray-900 font-mono bg-gray-100 p-2 rounded"
              >
                {@invitation.token}
              </p>
            </div>
          </div>

          <div class="space-y-4">
            <div class="flex items-center">
              <.input
                type="checkbox"
                field={f[:set_expiration]}
                class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label for="set-expiration" class="ml-2 block text-sm text-gray-900">
                Set expiration date
              </label>
            </div>

            <div
              :if={Phoenix.HTML.Form.normalize_value("checkbox", f[:set_expiration].value)}
              class="pl-6"
            >
              <.input
                type="date"
                label="Expires on"
                field={f[:expires_on]}
                min={current_date(@timezone)}
                phx-target={@myself}
              />
              <p class="mt-1 text-sm text-gray-500">
                Invitation will expire at the end of this day
              </p>
            </div>
          </div>

          <div class="flex justify-end space-x-3 pt-4">
            <.button type="button" variant="light" phx-click={JS.patch(usher_path())}>
              Cancel
            </.button>
            <.button type="submit">
              Save
            </.button>
          </div>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{invitation: invitation} = assigns, socket) do
    changeset = InvitationFormData.create_changeset(invitation)

    # Convert expires_at datetime to expires_on date for form display
    expires_on =
      if invitation.expires_at do
        DateTime.to_date(invitation.expires_at)
      else
        nil
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:expires_on, expires_on)
      |> assign(:form, to_form(changeset))
      |> assign_new(:timezone, fn -> "Etc/UTC" end)

    {:ok, socket}
  end

  def handle_event("user_timezone", unsigned_params, socket) do
    %{"timezone" => timezone} = unsigned_params

    socket =
      socket
      |> assign(:timezone, timezone)

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"invitation" => invitation_params}, socket) do
    updated_changeset =
      socket.assigns.form.data
      |> InvitationFormData.update_changeset(invitation_params)

    {:noreply, assign(socket, form: to_form(updated_changeset))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"invitation" => invitation_params}, socket) do
    form_changeset =
      socket.assigns.form.data
      |> InvitationFormData.update_changeset(invitation_params)

    case Ecto.Changeset.apply_action(form_changeset, :validate) do
      {:ok, form_data} ->
        invitation_attrs =
          Map.new()
          |> Map.put(:name, form_data.name)
          |> Map.put_new_lazy(:expires_at, fn ->
            convert_expires_on_to_expires_at(
              form_data.expires_on,
              form_data.set_expiration,
              socket.assigns.timezone
            )
          end)

        create_invitation(socket, invitation_attrs)

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp create_invitation(socket, invitation_attrs) do
    case Usher.create_invitation(invitation_attrs) do
      {:ok, invitation} ->
        send_update(socket.assigns.save_target, new_invitation: invitation)

        {:noreply,
         socket
         |> put_flash(:info, "Invitation created successfully")
         |> push_patch(to: usher_path())}

      {:error, %Ecto.Changeset{} = changeset} ->
        error_message =
          Enum.map_join(changeset.errors, ", ", fn {field, {msg, _}} -> "#{field}: #{msg}" end)

        {:noreply,
         socket
         |> put_flash(:error, "Failed to create invitation: #{error_message}")
         |> assign(form: to_form(changeset))}
    end
  end

  defp convert_expires_on_to_expires_at(expires_on, set_expiration, timezone) do
    if set_expiration && expires_on && expires_on != "" do
      date_to_end_of_day_utc!(expires_on, timezone)
    else
      nil
    end
  end
end
