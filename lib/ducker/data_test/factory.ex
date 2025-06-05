defmodule Ducker.DataTest.Factory do
  # alias Ducker.FileHelper
  alias Ducker.DataTest.Generic
  alias Ducker.DataTest.Unique
  alias Ducker.DataTest.Relationship

  # @doc """
  # Loads validation files from a directory.

  # ## Options:
  #   - `:filter` - A function to filter files. It should take a file name as an argument and return true or false.
  # """

  # def from_dir(dir, opts \\ []) do
  #   filter_fn = Keyword.get(opts, :filter)

  #   case FileHelper.list_files(dir, ext: ".yaml", exclude_hidden: true, filter: filter_fn) do
  #     {:ok, files} ->
  #       Enum.map(files, &from_file/1) |> List.flatten()

  #     {:error, reason} ->
  #       raise "failed loading data tests config from #{dir}:\n#{Exception.format_banner(:error, reason)}"
  #   end
  # end

  # def from_file(filename) do
  #   case YamlElixir.read_from_file(filename) do
  #     {:ok, config} ->
  #       create_tests(filename, config)

  #     {:error, reason} ->
  #       raise "failed parsing data test config file #{filename}:\n#{Exception.format_banner(:error, reason)}"
  #   end
  # end

  # def from_string(str) do
  #   case YamlElixir.read_from_string(str) do
  #     {:ok, config} ->
  #       create_tests("n/a", config)

  #     {:error, reason} ->
  #       raise "failed parsing data test config:\n#{Exception.format_banner(:error, reason)}"
  #   end
  # end

  @doc """
  Creates data tests from a specification map.
  """
  def create_tests(%{"table" => table, "data_tests" => data_tests}) do
    data_tests
    |> Enum.map(fn test_spec -> create_test(table, test_spec) end)
  end

  def create_tests(_spec), do: {:error, "invalid specification"}

  defp create_test(table, %{"assert" => assert} = spec) do
    %Generic{
      table: table,
      assert: assert,
      where_clause: spec["where"],
      type: spec["type"]
    }
    |> Generic.create_test_sql()
  end

  defp create_test(table, %{"unique" => fields} = spec) do
    %Unique{
      table: table,
      fields: fields,
      where_clause: spec["where"],
      type: spec["type"]
    }
    |> Unique.create_test_sql()
  end

  defp create_test(table, %{"to" => to} = spec) do
    %Relationship{
      table: table,
      fields: spec["fields"],
      to: to,
      to_fields: spec["to_fields"],
      where_clause: spec["where"],
      type: spec["type"]
    }
    |> Relationship.create_test_sql()
  end

  defp create_test(_table, _spec) do
    {:error, "invalid data test specification"}
  end
end
