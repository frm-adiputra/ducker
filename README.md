
# Ducker

<p>
    <a href="https://hex.pm/packages/ducker"><img alt="Hex.pm Version" src="https://img.shields.io/hexpm/v/ducker?style=for-the-badge"></a>
    <a href="https://hexdocs.pm/ducker/readme.html"><img alt="Hex.pm Documentation" src="https://img.shields.io/badge/HEX-doc-blue?style=for-the-badge"></a>
</p>

ELT (extract load transform) powered by [DuckDB](https://duckdb.org/) and [Elixir](https://elixir-lang.org/)

## Features

- Structure your queries as directories and files for easy management and version control
- Test your data. Specify your testing using YAML
- Flexibility by using DuckDB's powerful SQL language

## Installation

The package can be installed by adding `ducker` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ducker, "~> 0.3.0"}
  ]
end
```

## Tutorial

Usage examples can be found in the [tutorial page](tutorial.livemd).
