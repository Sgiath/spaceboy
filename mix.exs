defmodule Spaceboy.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :spaceboy,
      version: @version,
      elixir: "~> 1.11",
      preferred_cli_env: [docs: :docs],
      consolidate_protocols: Mix.env() != :test,
      deps: deps(),
      package: package(),

      # Docs
      name: "Spaceboy",
      source_url: "https://git.sr.ht/~sgiath/spaceboy",
      homepage_url: "gemini://sgiath.dev/projects/spaceboy/",
      description: """
      Spaceboy - Gemini server framework for Elixir
      Heavily inspired by Phoenix. Heavily simplified.
      """,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :public_key]
    ]
  end

  defp deps do
    [
      {:ranch, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:mime, "~> 1.5"},
      {:typed_struct, "~> 0.2"},

      # Docs dependencies (for links to work properly)
      {:ex_doc, "~> 0.22", only: :docs},
      {:plug, "~> 1.11", only: :docs, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Sgiath"],
      licences: ["MIT"],
      links: %{
        "sourcehut" => "https://git.sr.ht/~sgiath/spaceboy",
        "gemini specs" => "gemini://gemini.circumlunar.space/"
      },
      files: ~w(lib priv mix.exs .formatter.exs README.md)
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      # main: "overview",
      # extra_section: "Guides",
      formatters: ["html", "epub"],
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: groups_for_modules()
    ]
  end

  defp extras do
    []
  end

  defp groups_for_extras do
    [
      # Introduction: ~r/guides\/introduction\/.?/,
      # Guides: ~r/guides\/[^\/]+\.md/
    ]
  end

  defp groups_for_modules do
    [
      Middlewares: [
        Spaceboy.Middleware,
        Spaceboy.Middleware.Logger
      ]
    ]
  end
end
