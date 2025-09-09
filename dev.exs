# Development server for Usher Web that simulates

defmodule Usher.Dev.Repo do
  use Ecto.Repo, otp_app: :usher_web, adapter: Ecto.Adapters.Postgres
end

defmodule Usher.Dev.Migration do
  use Ecto.Migration

  def change do
    # Set latest migration version for Usher.
    Usher.Migration.migrate_to_version(4)
  end
end

defmodule Usher.Dev.Router do
  use Phoenix.Router, helpers: false

  import Usher.Web.Router

  # pipeline :browser do
  #   plug :fetch_session
  # end

  scope "/" do
    # pipe_through :browser

    usher_dashboard("/usher")
  end
end

defmodule Usher.Dev.Endpoint do
  use Phoenix.Endpoint, otp_app: :usher_web

  socket "/live", Phoenix.LiveView.Socket
  socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket

  plug Phoenix.LiveReloader
  plug Phoenix.CodeReloader

  plug Plug.Static,
    at: "/",
    from: :usher_web,
    gzip: false,
    only: ~w(app.css app.js fonts favicon.ico)

  plug Plug.Session,
    store: :cookie,
    key: "_usher_web_key",
    signing_salt: "5Ralb9W4sku"

  plug Usher.Dev.Router
end

defmodule Usher.Dev.ErrorHTML do
  use Phoenix.Component

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

port = "PORT" |> System.get_env("4000") |> String.to_integer()

Application.put_env(:usher_web, Usher.Dev.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {0, 0, 0, 0}, port: port],
  check_origin: false,
  debug_errors: true,
  http: [port: port],
  live_view: [signing_salt: "5mb8DerJO7CaFVfw0eKEJ7bHCErNfuii"],
  pubsub_server: Usher.Dev.PubSub,
  render_errors: [formats: [html: Usher.Dev.ErrorHTML], layout: false],
  secret_key_base: "KqApumXKtHhq5qhya6KjtLY8i5ErF16wfeOHOeN8fnjFrcB6WpeLBRoFRObtlDWI",
  url: [host: "localhost"],
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch=always)]}
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/usher/web/(pages|live|components)/.*(ex|heex)$"
    ]
  ]
)

Application.put_env(:usher_web, Usher.Dev.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 2345,
  database: "usher_dev",
  username: "usher_web_dev"
)

Application.put_env(:phoenix, :serve_endpoints, true)
Application.put_env(:phoenix, :persistent, true)

Application.put_env(:usher, :repo, Usher.Dev.Repo)

Task.async(fn ->
  {:ok, _} = Application.ensure_all_started(:esbuild)
  {:ok, _} = Application.ensure_all_started(:tailwind)

  children = [
    {Phoenix.PubSub, [name: Usher.Dev.PubSub, adapter: Phoenix.PubSub.PG2]},
    {Usher.Dev.Repo, []},
    {Usher.Dev.Endpoint, []}
  ]

  Ecto.Adapters.Postgres.storage_up(Usher.Dev.Repo.config())

  {:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one)

  Ecto.Migrator.run(
    Usher.Dev.Repo,
    [{0, Usher.Dev.Migration}],
    :up,
    all: true
  )

  IO.puts("✅ Database setup complete!")
  IO.puts("🌐 Web server running on http://localhost:#{port}/usher")

  Process.sleep(:infinity)
end)
