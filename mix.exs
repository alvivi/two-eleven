defmodule TwoEleven.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: preferred_cli_env(),
      releases: releases(),

      # Docs
      name: "TwoEleven",
      source_url: "https://github.com/alvivi/two-eleven",
      homepage_url: "https:two-eleven.alvivi.dev",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:excoveralls, "~> 0.12", only: :test},
      # required to run "mix format" on ~H/.heex files from the umbrella root
      {:phoenix_live_view, ">= 0.0.0"}
    ]
  end

  defp aliases do
    [
      setup: ["cmd mix setup"],
      "assets.deploy": ["cmd mix assets.deploy"]
    ]
  end

  defp preferred_cli_env do
    [
      "coveralls.github": :test,
      "coveralls.html": :test,
      coveralls: :test
    ]
  end

  defp releases do
    [
      two_eleven: [
        include_executables_for: [:unix],
        applications: [
          two_eleven: :permanent,
          two_eleven_web: :permanent,
          runtime_tools: :permanent
        ]
      ]
    ]
  end
end
