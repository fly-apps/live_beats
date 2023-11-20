defmodule LiveBeats.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_beats,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {LiveBeats.Application, []},
      extra_applications: [:logger, :runtime_tools]
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
      {:castore, "~> 1.0.0"},
      {:ecto_network, "~> 1.3.0"},
      {:ecto_sql, "~> 3.11.0"},
      {:esbuild, "~> 0.8.0", runtime: Mix.env() == :dev},
      {:finch, "~> 0.16.0"},
      {:floki, "~> 0.35.0", only: :test},
      {:gettext, "~> 0.23.0"},
      {:heroicons, "~> 0.5.3"},
      {:jason, "~> 1.4.0"},
      {:libcluster, "~> 3.3.0"},
      {:mint, "~> 1.5.0"},
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.4.0"},
      {:phoenix_html, "~> 3.3.0", override: true},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:phoenix_live_reload, "~> 1.4.0", only: :dev},
      {:phoenix_live_view, "~> 0.20.0"},
      {:plug_cowboy, "~> 2.6.0"},
      {:postgrex, "~> 0.17.0"},
      {:swoosh, "~> 1.14.0"},
      {:tailwind, "~> 0.2.0"},
      {:telemetry_metrics, "~> 0.6.0"},
      {:telemetry_poller, "~> 1.0.0"},
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
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end
end
