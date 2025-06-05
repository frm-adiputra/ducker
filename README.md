# Ducker

[![Hex.pm Version](https://img.shields.io/hexpm/v/ducker?style=for-the-badge)](https://hexdocs.pm/ducker)

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
    {:ducker, "~> 0.2.0"}
  ]
end
```

The docs can be found at <https://hexdocs.pm/ducker>.
