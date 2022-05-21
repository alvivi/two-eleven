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
      {:excoveralls, "~> 0.12", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["cmd mix setup"]
    ]
  end

  defp preferred_cli_env do
    [
      "coveralls.github": :test,
      "coveralls.html": :test,
      coveralls: :test
    ]
  end
end
