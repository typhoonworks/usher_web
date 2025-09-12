defmodule Usher.Web.DataCase do
  @moduledoc """
  Defines the setup for tests requiring access to the application's data layer.

  Use in tests that only require access to the data layer.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Usher.Web.DataCase

      alias Usher.Web.TestRepo
    end
  end

  setup context do
    setup_sandbox(context)

    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Usher.Web.TestRepo, shared: not tags[:async])

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
    end)
  end
end
