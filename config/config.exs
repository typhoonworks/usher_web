# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures Elixir's Logger
config :logger, level: :warning
config :logger, :console, format: "$time $metadata[$level] $message\n"

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

if config_env() == :dev do
  # Set a higher stacktrace during development. Avoid configuring such
  # in production as building large stacktraces may be expensive.
  config :phoenix, :stacktrace_depth, 20

  # Initialize plugs at runtime for faster development compilation
  config :phoenix, :plug_init_mode, :runtime

  config :phoenix_live_view,
    # Include HEEx debug annotations as HTML comments in rendered markup
    debug_heex_annotations: true,
    debug_attributes: true,
    # Enable helpful, but potentially expensive runtime checks
    enable_expensive_runtime_checks: true

  # Configure esbuild (the version is required)
  config :esbuild,
    version: "0.25.0",
    default: [
      args: ~w(
        js/app.js
        --bundle
        --target=es2017
        --outdir=../priv/static/
      ),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]

  # Configure tailwind (the version is required)
  config :tailwind,
    version: "3.4.3",
    default: [
      args: ~w(
        --config=tailwind.config.js
        --minify
        --input=css/app.css
        --output=../priv/static/app.css
        --watch=always
      ),
      cd: Path.expand("../assets", __DIR__)
    ]
end
