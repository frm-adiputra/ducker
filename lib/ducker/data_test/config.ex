defmodule Ducker.DataTest.Config do
  alias Ducker.FileHelper
  alias Ducker.DataTest.Generic
  alias Ducker.DataTest.Unique
  alias Ducker.DataTest.Relationship

  @doc """
  Loads validation files from a directory.

  ## Options:
    - `:filter` - A function to filter files. It should take a file name as an argument and return true or false.
  """
  def from_dir(dir, opts \\ []) do
    filter_fn = Keyword.get(opts, :filter)

    case FileHelper.list_files(dir, ext: ".yaml", exclude_hidden: true, filter: filter_fn) do
      {:ok, files} ->
        Enum.map(files, &from_file/1) |> List.flatten()

      {:error, reason} ->
        raise "failed loading data tests config from #{dir}:\n#{Exception.format_banner(:error, reason)}"
    end
  end

  def from_file(filename) do
    case YamlElixir.read_from_file(filename) do
      {:ok, config} ->
        create_tests(filename, config)

      {:error, reason} ->
        raise "failed parsing data test config file #{filename}:\n#{Exception.format_banner(:error, reason)}"
    end
  end

  def from_string(str) do
    case YamlElixir.read_from_string(str) do
      {:ok, config} ->
        create_tests("n/a", config)

      {:error, reason} ->
        raise "failed parsing data test config:\n#{Exception.format_banner(:error, reason)}"
    end
  end

  defp create_tests(filename, cfg) do
    %{
      "table" => table,
      "data_tests" => data_tests
    } = cfg

    data_tests
    |> Enum.map(fn test_cfg -> create_test(filename, table, test_cfg) end)
  end

  defp create_test(file, table, %{"test" => expr} = cfg) do
    %Generic{
      file: file,
      table: table,
      expression: expr,
      where_clause: cfg["where"],
      type: cfg["type"]
    }
    |> Generic.create_test_sql()
  end

  defp create_test(file, table, %{"unique" => fields} = cfg) do
    %Unique{
      file: file,
      table: table,
      fields: fields,
      where_clause: cfg["where"],
      type: cfg["type"]
    }
    |> Unique.create_test_sql()
  end

  defp create_test(file, table, %{"to" => to} = cfg) do
    %Relationship{
      file: file,
      table: table,
      fields: cfg["fields"],
      to: to,
      to_fields: cfg["to_fields"],
      where_clause: cfg["where"],
      type: cfg["type"]
    }
    |> Relationship.create_test_sql()
  end

  defp create_test(file, _table, _cfg) do
    {:error, "invalid data test config in file: #{file}"}
  end
end
