import Config

config :usher_web, Usher.Web.Test.Endpoint,
  http: [port: 4005],
  check_origin: false,
  debug_errors: true,
  live_view: [signing_salt: "5mb8DerJO7CaFVfw0eKEJ7bHCErNfuii"],
  pubsub_server: Usher.Dev.PubSub,
  render_errors: [formats: [html: Usher.Web.Test.ErrorHTML], layout: false],
  secret_key_base: "KqApumXKtHhq5qhya6KjtLY8i5ErF16wfeOHOeN8fnjFrcB6WpeLBRoFRObtlDWI",
  url: [host: "localhost"]

config :usher_web, Usher.Web.TestRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 2345,
  database: "usher_web_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :usher_web, :ecto_repos, [Usher.Web.TestRepo]

config :usher, :repo, Usher.Web.TestRepo
