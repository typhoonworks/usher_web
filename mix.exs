defmodule Usher.Web.MixProject do
  use Mix.Project

  @version "1.0.2"
  @source_url "https://github.com/typhoonworks/usher_web"

  def project do
    [
      app: :usher_web,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      package: package(),
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      dialyzer: dialyzer()
    ]
  end

  def cli do
    [preferred_envs: ["test.setup": :test, test: :test]]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Usher.Web.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:tzdata, "~> 1.1"},

      # Phoenix
      {:jason, "~> 1.2"},
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_ecto, "~> 4.6"},

      # Usher
      {:usher, "~> 0.5.1"},

      # Tests Only
      {:floki, ">= 0.30.0", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:mimic, "~> 2.1", only: :test},

      # Development
      {:bandit, "~> 1.5"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true},
      {:finch, "~> 0.13"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:postgrex, "~> 0.20", only: [:dev, :test]},
      {:tailwind, "~> 0.3.0", runtime: Mix.env() == :dev},
      {:tidewave, "~> 0.5", only: :dev}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "dev.setup": ["cmd ./scripts/dev_setup.sh"],
      dev: "run --no-halt dev.exs",
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.deploy": [
        "tailwind usher_web --minify",
        "esbuild usher_web --minify",
        "phx.digest"
      ],
      "test.setup": [
        "ecto.drop --quiet",
        "ecto.create",
        "ecto.migrate --migrations-path test/support/migrations"
      ],
      lint: ["format", "dialyzer", "credo --strict"]
    ]
  end

  defp docs do
    [
      main: "overview",
      authors: ["Arda C. Tugay"],
      logo: "assets/logo.svg",
      api_reference: false,
      source_ref: "v#{@version}",
      source_url: @source_url,
      extra_section: "GUIDES",
      extras: docs_guides(),
      groups_for_modules: [
        Authentication: [
          Usher.Web.Authentication,
          Usher.Web.Resolver
        ],
        Router: [
          Usher.Web.Router
        ],
        LiveViews: [
          Usher.Web.Components.InvitationFormComponent.InvitationFormData
        ]
      ]
    ]
  end

  defp docs_guides do
    [
      "guides/overview.md",
      "guides/installation.md",
      "guides/getting-started.md",
      "guides/configuration.md",
      "guides/contributing.md"
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [
        :mix,
        :ecto,
        :postgrex,
        :ex_unit,
        :phoenix,
        :phoenix_html,
        :phoenix_live_view
      ],
      plt_core_path: "_build/#{Mix.env()}",
      flags: [:error_handling, :underspecs, :missing_return]
    ]
  end

  defp package do
    [
      name: "usher_web",
      maintainers: ["Arda C. Tugay"],
      licenses: ["MIT"],
      links: %{GitHub: @source_url},
      files: ~w[lib priv/static* .formatter.exs mix.exs README* LICENSE* licenses/*]
    ]
  end

  defp description do
    """
    Usher Web is a web interface for the Usher invitation link management library.
    """
  end
end
