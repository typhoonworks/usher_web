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
      alias Usher.Web.Test.Router

      @endpoint Usher.Web.Test.Endpoint
    end
  end

  setup context do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Usher.Web.TestRepo, shared: not context[:async])

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
    end)

    :ok
  end
end
