defmodule Usher.Web.Live.InvitationsListTest do
  use Usher.Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  import Usher.Web.Test.InvitationFixtures

  describe "no invitations" do
    test "renders empty state", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/usher")

      assert html =~ "Invitations"
      assert html =~ "View and manage invitations"

      assert html =~ "No invitations yet"
    end
  end

  describe "invitation table rendering" do
    setup %{conn: conn} do
      # This has no expires_at
      invitation1 = create_invitation()
      add_usage_to_invitation(invitation1)

      invitation2 = create_expired_invitation()
      invitation3 = create_expiring_soon_invitation()

      {:ok, view, _html} = live(conn, "/usher")
      %{view: view, invitations: [invitation1, invitation2, invitation3]}
    end

    test "displays invitation names correctly tr", %{view: view, invitations: invitations} do
      [invitation1, invitation2, invitation3] = invitations
      assert has_element?(view, "#invitations tr", invitation1.name)
      assert has_element?(view, "#invitations tr", invitation2.name)
      assert has_element?(view, "#invitations tr", invitation3.name)
    end

    test "displays invitation creation dates", %{view: view} do
      current_date = Date.utc_today()
      current_month_year = Calendar.strftime(current_date, "%b %d, %Y")
      assert has_element?(view, "#invitations tr", current_month_year)
    end

    test "displays usage count correctly", %{view: view, invitations: [invitation1 | _]} do
      assert has_element?(view, "#invitations-#{invitation1.id} td", "1 user")
    end

    test "displays invitation links and copy buttons", %{view: view} do
      # Check that invitation links are displayed
      assert has_element?(view, "a[href*='http://localhost:4000']")

      # Check that copy buttons are present
      assert has_element?(view, "[data-clipboard-text]")
      assert has_element?(view, ".hero-clipboard")
    end

    test "displays edit and delete action buttons", %{view: view} do
      # Check edit buttons
      assert has_element?(view, "a[href*='/edit']")
      assert has_element?(view, ".hero-pencil")

      # Check delete buttons
      assert has_element?(view, "[phx-click='delete_invitation']")
      assert has_element?(view, ".hero-trash")
    end
  end

  describe "new invitation modal rendering" do
    test "opens new invitation modal when navigating to new action", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/usher/new")

      assert has_element?(view, "#invitation-modal")
      assert has_element?(view, "#invitation-form")
      assert has_element?(view, "h2", "New Invitation")
    end

    test "shows form fields in new invitation modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/usher/new")

      assert has_element?(view, "input[name='invitation[name]']")
      assert has_element?(view, "input[name='invitation[set_expiration]'][type='checkbox']")
      assert has_element?(view, "button[type='submit']", "Save")
    end

    test "closes modal when cancel is clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/usher/new")

      assert has_element?(view, "#invitation-modal")

      view
      |> element("button", "Cancel")
      |> render_click()

      assert_patch(view, "/usher/")
      refute has_element?(view, "#invitation-modal")
    end
  end

  describe "creating new invitations" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, "/usher/new")
      %{view: view}
    end

    test "successfully creates invitation with valid data", %{view: view, conn: _conn} do
      invitation_name = Ecto.UUID.generate()

      form_data = %{
        "name" => invitation_name,
        "set_expiration" => "false"
      }

      view
      |> form("#invitation-form", invitation: form_data)
      |> render_submit()

      assert_patch(view, "/usher/")

      # Verify invitation was actually created in the database
      invitations = Usher.list_invitations()
      assert Enum.any?(invitations, &(&1.name == invitation_name))
    end

    test "handles validation errors when creating invitation", %{view: view} do
      # Test empty name validation - should show validation error
      form_data = %{
        "name" => "",
        "set_expiration" => "false"
      }

      view
      |> form("#invitation-form", invitation: form_data)
      |> render_submit()

      assert has_element?(view, "input + p", "can't be blank")
    end

    test "shows expiration date field when set_expiration is checked", %{view: view} do
      invitation_name = Ecto.UUID.generate()

      form_data = %{
        "name" => invitation_name,
        "set_expiration" => "true"
      }

      html =
        view
        |> form("#invitation-form", invitation: form_data)
        |> render_change()

      assert html =~ "Expires on"
      # The date field appears after the checkbox is checked and form is changed
      assert has_element?(view, "input[name='invitation[expires_on]'][type='date']")
    end

    test "creates invitation with expiration date", %{view: view} do
      tomorrow = Date.add(Date.utc_today(), 1)
      invitation_name = Ecto.UUID.generate()

      # First change the form to show expiration field
      form_data_initial = %{
        "name" => invitation_name,
        "set_expiration" => "true"
      }

      view
      |> form("#invitation-form", invitation: form_data_initial)
      |> render_change()

      # Check if the date field appeared
      # Then submit with the date
      form_data_final = %{
        "name" => "Expiring Invitation",
        "set_expiration" => "true",
        "expires_on" => Date.to_string(tomorrow)
      }

      view
      |> form("#invitation-form", invitation: form_data_final)
      |> render_submit()

      assert_patch(view, "/usher/")

      # Verify invitation was created with expiration
      invitations = Usher.list_invitations()
      expiring_invitation = Enum.find(invitations, &(&1.name == "Expiring Invitation"))
      assert expiring_invitation.expires_at != nil
    end

    test "validates expiration date when set_expiration is true", %{view: view} do
      # First enable expiration
      view
      |> form("#invitation-form", invitation: %{"set_expiration" => "true"})
      |> render_change()

      invitation_name = Ecto.UUID.generate()

      # Then try to submit with empty date
      form_data = %{
        "name" => invitation_name,
        "set_expiration" => "true"
      }

      view
      |> form("#invitation-form", invitation: form_data)
      |> render_submit()

      assert has_element?(view, "input + p", "can't be blank")
    end

    test "new invitation appears in list after successful creation", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/usher/new")

      invitation_name = Ecto.UUID.generate()

      form_data = %{
        "name" => invitation_name,
        "set_expiration" => "false"
      }

      view
      |> form("#invitation-form", invitation: form_data)
      |> render_submit()

      # Navigate back to list and verify the new invitation appears
      {:ok, view, _html} = live(conn, "/usher")

      assert [invitation] = Usher.list_invitations()
      assert has_element?(view, "#invitations #invitations-#{invitation.id}", invitation_name)
    end
  end

  describe "editing invitations" do
    setup %{conn: conn} do
      invitation = create_invitation()
      {:ok, view, _html} = live(conn, "/usher/#{invitation.id}/edit")

      %{view: view, invitation: invitation}
    end

    test "opens edit invitation modal", %{view: view} do
      assert has_element?(view, "#invitation-modal")
      assert has_element?(view, "#invitation-modal #invitation-form")
      assert has_element?(view, "#invitation-modal h2", "Edit Invitation")
    end

    test "pre-populates form with existing invitation data", %{view: view, invitation: invitation} do
      assert has_element?(
               view,
               "#invitation-modal input[name='invitation[name]'][value='#{invitation.name}']"
             )

      assert has_element?(view, "#invitation-modal p", invitation.token)
    end

    test "successfully updates invitation", %{view: view, invitation: invitation} do
      invitation_name = Ecto.UUID.generate()

      form_data = %{
        "name" => invitation_name,
        "set_expiration" => "false"
      }

      view
      |> form("#invitation-form", invitation: form_data)
      |> render_submit()

      assert_patch(view, "/usher/")

      # Verify invitation was actually updated in the database
      updated_invitation = Usher.get_invitation!(invitation.id)
      assert updated_invitation.name == invitation_name
    end

    test "handles update validation errors", %{view: view} do
      form_data = %{
        "name" => "",
        "set_expiration" => "false"
      }

      view
      |> form("#invitation-form", invitation: form_data)
      |> render_submit()

      assert has_element?(view, "#invitation-modal input + p", "can't be blank")
    end

    test "updates invitation with expiration date", %{view: view, invitation: invitation} do
      tomorrow = Date.add(Date.utc_today(), 1)
      invitation_name = Ecto.UUID.generate()

      # First change the form to show expiration field
      form_data_initial = %{
        "name" => invitation_name,
        "set_expiration" => "true"
      }

      view
      |> form("#invitation-form", invitation: form_data_initial)
      |> render_change()

      # Check if the date field appeared
      # Then submit with the date
      form_data_final = %{
        "name" => invitation_name,
        "set_expiration" => "true",
        "expires_on" => Date.to_string(tomorrow)
      }

      view
      |> form("#invitation-form", invitation: form_data_final)
      |> render_submit()

      assert_patch(view, "/usher/")

      # Verify invitation was updated with expiration
      updated_invitation = Usher.get_invitation!(invitation.id)
      assert updated_invitation.name == invitation_name
      assert updated_invitation.expires_at != nil
    end

    test "updated invitation reflects changes in list", %{conn: conn, invitation: invitation} do
      invitation_name = Ecto.UUID.generate()

      form_data = %{
        "name" => invitation_name,
        "set_expiration" => "false"
      }

      {:ok, edit_view, _html} = live(conn, "/usher/#{invitation.id}/edit")

      edit_view
      |> form("#invitation-form", invitation: form_data)
      |> render_submit()

      # Navigate back to list and verify the changes
      {:ok, list_view, _html} = live(conn, "/usher")

      assert has_element?(list_view, "#invitations", invitation_name)
    end
  end

  describe "deleting invitations" do
    setup %{conn: conn} do
      invitation = create_invitation(%{name: Ecto.UUID.generate()})
      {:ok, view, _html} = live(conn, "/usher")
      %{view: view, invitation: invitation}
    end

    test "shows delete confirmation modal when delete button is clicked", %{
      view: view,
      invitation: invitation
    } do
      refute has_element?(view, "#delete-confirmation-modal")

      view
      |> element("[phx-click='delete_invitation'][phx-value-id='#{invitation.id}']")
      |> render_click()

      assert has_element?(view, "#delete-confirmation-modal")
      assert has_element?(view, "#delete-confirmation-modal h3", "Confirm Deletion")

      assert has_element?(
               view,
               "#delete-confirmation-modal p",
               "Are you sure you want to delete this invitation?"
             )
    end

    test "cancels deletion when cancel button is clicked", %{view: view, invitation: invitation} do
      # Open confirmation modal
      view
      |> element("[phx-click='delete_invitation'][phx-value-id='#{invitation.id}']")
      |> render_click()

      assert has_element?(view, "#delete-confirmation-modal")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, "#delete-confirmation-modal")
    end

    test "successfully deletes invitation when confirmed", %{view: view, invitation: invitation} do
      # Open confirmation modal
      view
      |> element("[phx-click='delete_invitation'][phx-value-id='#{invitation.id}']")
      |> render_click()

      assert has_element?(view, "#delete-confirmation-modal")

      # Confirm deletion
      view
      |> element("[phx-click='confirm_delete_invitation'][phx-value-id='#{invitation.id}']")
      |> render_click()

      # Modal should be closed
      refute has_element?(view, "#delete-confirmation-modal")

      # Should show success flash
      assert render(view) =~ "Invitation deleted successfully"

      # Invitation should be removed from table
      refute has_element?(view, "#invitations tbody tr", invitation.name)

      # Verify invitation was actually deleted from database
      assert_raise Ecto.NoResultsError, fn ->
        Usher.get_invitation!(invitation.id)
      end
    end
  end

  describe "copy to clipboard functionality" do
    setup %{conn: conn} do
      invitation = create_invitation()
      {:ok, view, _html} = live(conn, "/usher")
      %{view: view, invitation: invitation}
    end

    test "shows success flash when copy succeeds", %{view: view} do
      view
      |> element("[phx-hook='CopyToClipboard']")
      |> render_hook("copy-to-clipboard-success", %{})

      assert render(view) =~ "Token link copied to clipboard"
    end

    test "shows error flash when copy fails", %{view: view} do
      view
      |> element("[phx-hook='CopyToClipboard']")
      |> render_hook("copy-to-clipboard-error", %{"error" => "Permission denied"})

      assert render(view) =~ "Failed to copy token link to clipboard: Permission denied"
    end
  end

  describe "invitation expiration helpers" do
    test "displays 'Never' for invitations without expiration", %{conn: conn} do
      create_never_expiring_invitation()

      {:ok, view, _html} = live(conn, "/usher")

      assert has_element?(view, "#invitations td span", "Never")
    end

    test "shows expired status with red styling", %{conn: conn} do
      create_expired_invitation()

      {:ok, view, _html} = live(conn, "/usher")

      assert has_element?(view, "#invitations td span.bg-red-100.text-red-800")
    end

    test "shows expiring soon status with yellow styling", %{conn: conn} do
      create_expiring_soon_invitation()

      {:ok, view, _html} = live(conn, "/usher")

      assert has_element?(view, "#invitations td span.bg-yellow-100.text-yellow-800")
    end

    test "shows future expiration with blue styling", %{conn: conn} do
      create_invitation(%{
        name: Ecto.UUID.generate(),
        expires_at:
          DateTime.utc_now()
          |> DateTime.add(30, :day)
          |> DateTime.truncate(:second)
      })

      {:ok, view, _html} = live(conn, "/usher")

      assert has_element?(view, "#invitations td span.bg-blue-100.text-blue-800")
    end
  end
end
