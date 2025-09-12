defmodule Usher.Web.ConnCase do
  @moduledoc """
  Defines the setup for tests requiring access to the presentation layer, i.e. LiveView

  Use in tests that require LiveView, as well as the data layer.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest

      import Usher.Web.DataCase

      alias Usher.Web.TestRepo
      alias Usher.Web.Test.Router

      @endpoint Usher.Web.Test.Endpoint
    end
  end

  setup context do
    Usher.Web.DataCase.setup_sandbox(context)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
