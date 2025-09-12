defmodule Usher.Web.Test.InvitationFixtures do
  @moduledoc """
  Test helpers for creating Usher invitations.
  """

  def create_invitation(attrs \\ %{}) do
    default_attrs = %{
      name: "Test Invitation #{System.unique_integer([:positive])}"
    }

    attrs = Map.merge(default_attrs, attrs)
    {:ok, invitation} = Usher.create_invitation(attrs)

    invitation
  end

  def create_expired_invitation do
    # Create invitation first without expiration, then update it to be expired
    {:ok, invitation} = Usher.create_invitation(%{name: Ecto.UUID.generate()})

    # Manually update the expires_at field to be in the past, truncated to seconds
    expired_at =
      DateTime.utc_now()
      |> DateTime.add(-30, :day)
      |> DateTime.truncate(:second)

    invitation
    |> Ecto.Changeset.change(%{expires_at: expired_at})
    |> Usher.Config.repo().update!()
  end

  def create_expiring_soon_invitation do
    create_invitation(%{
      name: Ecto.UUID.generate(),
      expires_at:
        DateTime.utc_now()
        |> DateTime.add(2, :day)
        |> DateTime.truncate(:second)
    })
  end

  def create_never_expiring_invitation(attrs \\ %{}) do
    attrs = Map.put(attrs, :expires_at, nil)

    create_invitation(attrs)
  end

  def add_usage_to_invitation(invitation) do
    {:ok, usage} =
      Usher.track_invitation_usage(invitation, :user, Ecto.UUID.generate(), :registered)

    usage
  end
end
