defmodule Spaceboy.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :spaceboy,
      version: @version,
      elixir: "~> 1.11",
      consolidate_protocols: Mix.env() != :test,
      deps: deps(),
      package: package(),

      # Docs
      name: "Spaceboy",
      source_url: "https://git.sr.ht/~sgiath/spaceboy",
      homepage_url: "https://hexdocs.pm/spaceboy/",
      description: """
      Spaceboy - Gemini server framework for Elixir
      Heavily inspired by Phoenix. Heavily simplified.
      """,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  defp deps do
    [
      {:ranch, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:mime, "~> 1.6"},
      {:typed_struct, "~> 0.2"},
      {:telemetry, "~> 0.4"},

      # Dev deps
      {:credo, "~> 1.5", only: :dev, runtime: false},

      # Docs dependencies
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Sgiath <sgiath@pm.me>"],
      licenses: ["WTFPL"],
      links: %{
        "SourceHut project" => "https://sr.ht/~sgiath/spaceboy/",
        "Gemini specs" => "https://gemini.circumlunar.space/"
      }
    ]
  end

  defp docs do
    [
      authors: [
        "Sgiath <sgiath@pm.me>",
        "Steven vanZyl <rushsteve1@rushsteve1.us>"
      ],
      main: "overview",
      formatters: ["html"],
      source_url_patter: "https://git.sr.ht/~sgiath/spaceboy/tree/master/item/%{path}#L%{line}",
      extra_section: "Guides",
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: groups_for_modules(),
      groups_for_functions: groups_for_functions(),
      nest_modules_by_prefix: [
        Spaceboy.Middleware
      ],
      deps: [
        plug: "https://hexdocs.pm/plug/"
      ]
    ]
  end

  defp extras do
    [
      # Introduction
      "docs/introduction/overview.md",
      "docs/introduction/installation.md",
      # Guides
      "docs/guides/deep-space-capsule.md"
    ]
  end

  defp groups_for_extras do
    [
      Introduction: ~r/docs\/introduction\/.?/,
      Guides: ~r/docs\/guides\/.?/
    ]
  end

  defp groups_for_modules do
    [
      Server: [
        Spaceboy.Server,
        Spaceboy.Conn,
        Spaceboy.Controller,
        Spaceboy.Router
      ],
      Middlewares: [
        Spaceboy.Middleware,
        Spaceboy.Middleware.Logger,
        Spaceboy.Middleware.RequestId,
        Spaceboy.Middleware.Telemetry
      ],
      Utils: [
        Spaceboy.PeerCert
      ],
      Internals: [
        Spaceboy.Header,
        Spaceboy.Specification,
        Spaceboy.Static
      ]
    ]
  end

  defp groups_for_functions do
    [
      Input: &(&1[:category] == :input),
      Success: &(&1[:category] == :success),
      Redirect: &(&1[:category] == :redirect),
      "Temporary Failure": &(&1[:category] == :temporary_failure),
      "Permanent Failure": &(&1[:category] == :permanent_failure),
      "Client Certificate Required": &(&1[:category] == :certificate),
      Utils: &(&1[:category] == :utils)
    ]
  end
end
