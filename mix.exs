defmodule Spaceboy.MixProject do
  use Mix.Project

  @version "0.3.2"

  def project do
    [
      app: :spaceboy,
      version: @version,
      elixir: "~> 1.18",
      consolidate_protocols: Mix.env() != :test,
      deps: deps(),
      package: package(),

      # Docs
      name: "Spaceboy",
      source_url: "https://github.com/Sgiath/spaceboy",
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
      extra_applications: [:logger, :eex, :public_key, :ssh]
    ]
  end

  defp deps do
    [
      # Required
      {:ranch, "~> 2.1"},
      {:mime, "~> 2.0"},
      {:typed_struct, "~> 0.3"},

      # Optional
      {:telemetry, "~> 1.3", optional: true},

      # Dev deps
      {:ex_check, "~> 0.16", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:ex_doc, "~> 0.36", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.2", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Sgiath <sgiath@sgiath.dev>"],
      licenses: ["WTFPL"],
      links: %{
        "GitHub" => "https://github.com/Sgiath/spaceboy",
        "Gemini specs" => "https://geminiprotocol.net"
      }
    ]
  end

  defp docs do
    [
      authors: [
        "Sgiath <sgiath@sgiath.dev>",
        "Steven vanZyl <rushsteve1@rushsteve1.us>"
      ],
      main: "overview",
      formatters: ["html"],
      source_url_patter: "https://github.com/Sgiath/spaceboy/blob/master/%{path}#L%{line}",
      extra_section: "Guides",
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: groups_for_modules(),
      groups_for_docs: groups_for_functions(),
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
      "docs/introduction/installation.md"
      # Guides
      # "docs/guides/deep-space-capsule.md"
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
        Spaceboy.Static,
        Spaceboy.Robots,
        Spaceboy.PeerCert
      ],
      Internals: [
        Spaceboy.Header,
        Spaceboy.Specification
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
