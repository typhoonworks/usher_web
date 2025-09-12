import Config

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
