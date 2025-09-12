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

case config_env() do
  env when env in [:dev, :test] ->
    import_config("#{env}.exs")

  _ ->
    :noop
end
