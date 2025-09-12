defmodule Usher.Web.TestRepo do
  @moduledoc false

  use Ecto.Repo, otp_app: :usher_web, adapter: Ecto.Adapters.Postgres
end
