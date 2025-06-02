defmodule Ducker.Validation.Config do
  alias Ducker.FileHelper
  alias Ducker.Validation.Config
  alias Ducker.Validation.Generic
  alias Ducker.Validation.Unique
  alias Ducker.Validation.Reference

  defstruct [:file, :config]

  @doc """
  Loads validation files from a directory.

  ## Options:
    - `:filter` - A function to filter files. It should take a file name as an argument and return true or false.
  """
  def from_dir(dir, opts \\ []) do
    filter_fn = Keyword.get(opts, :filter)

    case FileHelper.list_files(dir, ext: ".yaml", exclude_hidden: true, filter: filter_fn) do
      {:ok, files} ->
        Enum.map(files, &parse_validation_file/1) |> List.flatten()

      {:error, reason} ->
        raise "failed loading validation files from #{dir}:\n#{Exception.format_banner(:error, reason)}"
    end
  end

  defp parse_validation_file(file) do
    case YamlElixir.read_from_file(file) do
      {:ok, yaml} ->
        cfg = %Config{file: file, config: yaml}
        table = cfg.config["table"]

        cfg.config["validations"]
        |> Enum.map(fn valCfg -> create_validation(file, table, valCfg) end)

      {:error, reason} ->
        raise "failed parsing validation file #{file}:\n#{Exception.format_banner(:error, reason)}"
    end
  end

  defp create_validation(file, table, %{"validate" => expr} = cfg) do
    %Generic{
      file: file,
      table: table,
      expression: expr,
      where_clause: cfg["where"],
      type: cfg["type"]
    }
    |> Generic.validate()
  end

  defp create_validation(file, table, %{"unique" => columns} = cfg) do
    %Unique{
      file: file,
      table: table,
      columns: columns,
      where_clause: cfg["where"],
      type: cfg["type"]
    }
    |> Unique.validate()
  end

  defp create_validation(file, table, %{"reference" => reference} = cfg) do
    %Reference{
      file: file,
      table: table,
      columns: cfg["columns"],
      reference: reference,
      foreign_columns: cfg["foreign_columns"],
      where_clause: cfg["where"],
      type: cfg["type"]
    }
    |> Reference.validate()
  end
end
