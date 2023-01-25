defmodule Example.MixProject do
  use Mix.Project

  def project do
    [
      # App config
      app: :example,
      version: "0.1.0",

      # Elixir config
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Releases
      default_release: :default,
      releases: [
        default: [
          include_executables_for: [:unix],
          applications: [
            example: :permanent
          ]
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Example.Application, []}
    ]
  end

  defp deps do
    [
      {:spaceboy, path: "../"},
      {:jason, "~> 1.4"},
      {:telemetry, "~> 1.2"}
    ]
  end
end
