defmodule Ducker.MixProject do
  use Mix.Project

  def project do
    [
      app: :ducker,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir ELT (extract load transform) using DuckDB",
      source_url: "https://github.com/frm-adiputra/ducker",
      package: [
        licenses: ["Apache-2.0"],
        links: %{"GitHub" => "https://github.com/frm-adiputra/ducker"}
      ],
      docs: [
        main: "Ducker",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      # extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:adbc, "~> 0.7.9"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false, warn_if_outdated: true},
      {:yaml_elixir, "~> 2.11.0"}
    ]
  end
end
