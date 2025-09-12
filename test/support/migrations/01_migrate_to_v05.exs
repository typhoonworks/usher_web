defmodule Usher.Web.Test.MigratateToV05 do
  use Ecto.Migration

  def change do
    # Set latest migration version for Usher.
    Usher.Migration.migrate_to_version(5)
  end
end
