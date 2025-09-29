defmodule Usher.Web.TestRouter do
  use Phoenix.Router

  import Usher.Web.Router

  pipeline :browser do
    plug :fetch_session
    plug :fetch_flash
  end

  scope "/" do
    pipe_through :browser

    usher_dashboard("/usher")
  end
end

defmodule Usher.Web.Test.Endpoint do
  use Phoenix.Endpoint, otp_app: :usher_web

  socket "/live", Phoenix.LiveView.Socket

  plug Plug.Session,
    store: :cookie,
    key: "_usher_web_key",
    signing_salt: "5Ralb9W4sku"

  plug Usher.Web.TestRouter
end

defmodule Usher.Web.Test.ErrorHTML do
  use Phoenix.Component

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

Application.ensure_all_started(:postgrex)
Application.ensure_all_started(:mimic)

_ = Usher.Web.TestRepo.__adapter__().storage_up(Usher.Web.TestRepo.config())

{:ok, _} = Usher.Web.TestRepo.start_link()
{:ok, _} = Usher.Web.Test.Endpoint.start_link()

Ecto.Adapters.SQL.Sandbox.mode(Usher.Web.TestRepo, :manual)

Mimic.copy(DateTime)
Mimic.copy(Application)

ExUnit.start(assert_receive_timeout: 500, refute_receive_timeout: 50, exclude: [:skip])
