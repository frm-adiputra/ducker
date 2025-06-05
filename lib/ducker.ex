defmodule Ducker do
  @moduledoc """
  Documentation for `Ducker`.
  """

  alias Ducker.Query
  alias Adbc.Connection, as: Conn
  alias Ducker.FileHelper
  alias Ducker.DataTest.Factory

  @enforce_keys [:conn, :work_dir]
  defstruct [:conn, :work_dir]

  @opaque t :: %__MODULE__{conn: Adbc.Connection.t(), work_dir: String.t()}

  @doc """
  Initializes a Ducker struct with a connection and work directory.
  """
  def new!(conn, work_dir) do
    d = %__MODULE__{conn: conn, work_dir: work_dir}

    execute_query_from_dir(d, :code.priv_dir(:ducker))
    |> Enum.each(fn
      {:error, reason} -> raise reason
      _ -> :ok
    end)

    set_file_search_path!(conn, work_dir)
    set_work_dir_var!(conn, work_dir)
    d
  end

  def execute_query_from_dir(%__MODULE__{} = ducker, dir, opts \\ []) do
    eex = Keyword.get(opts, :eex, false)
    dir = Path.expand(dir, ducker.work_dir)
    bindings = if eex, do: [assigns: [work_dir: ducker.work_dir]], else: nil
    filter_fn = Keyword.get(opts, :filter)

    with {:ok, files} <-
           FileHelper.list_files(dir, ext: ".sql", exclude_hidden: true, filter: filter_fn) do
      files
      |> Stream.map(&Path.join(dir, &1))
      |> Stream.map(fn file -> execute_query_from_file(ducker, file, bindings) end)
      |> Stream.flat_map(& &1)
      |> Enum.to_list()
    end
  end

  def execute_query_from_file(%__MODULE__{} = ducker, file, bindings) do
    with {:ok, content} <- File.read(file) do
      String.split(content, "---")
      |> Stream.with_index(fn x, i -> {i + 1, x} end)
      |> Stream.map(fn {i, x} -> eval_query({relative_path(ducker, file), i, x}, bindings) end)
      |> Stream.map(fn x -> execute_query(ducker, x) end)
      |> Stream.map(&format_result/1)
    end
  end

  def execute_test_from_dir(%__MODULE__{} = ducker, dir, opts \\ []) do
    dir = Path.expand(dir, ducker.work_dir)
    filter_fn = Keyword.get(opts, :filter)

    with {:ok, files} <-
           FileHelper.list_files(dir, ext: ".yaml", exclude_hidden: true, filter: filter_fn) do
      files
      |> Stream.map(&Path.join(dir, &1))
      |> Stream.map(fn file -> execute_test_from_file(ducker, file) end)
      |> Stream.flat_map(& &1)
      |> Enum.to_list()
    end
  end

  def execute_test_from_file(%__MODULE__{} = ducker, file) do
    with {:ok, content} <- File.read(file) do
      String.split(content, "\n---\n")
      |> Stream.with_index(fn x, i -> {i + 1, x} end)
      |> Stream.map(fn {i, x} -> parse_yaml({relative_path(ducker, file), i, x}) end)
      |> Stream.map(fn x -> create_tests(x) end)
      |> Stream.flat_map(& &1)
      |> Stream.map(fn x -> execute_test(ducker, x) end)
      |> Stream.map(&format_result/1)
    end
  end

  defp eval_query({filename, query_index, tmpl}, bindings) do
    case Query.eval_query(tmpl, bindings) do
      {:error, reason} ->
        {:error, {:query, %{filename: filename, index: query_index}}, reason}

      {:ok, q} ->
        {:ok, {:query, %{filename: filename, index: query_index, query: q}}}
    end
  end

  defp execute_query(%__MODULE__{} = ducker, {:ok, {:query, _} = v}), do: execute(ducker, v)
  defp execute_query(%__MODULE__{}, {:error, _, _} = err), do: err

  defp parse_yaml({filename, index, yaml}) do
    case YamlElixir.read_from_string(yaml) do
      {:error, reason} ->
        {:error, {:yaml, %{filename: filename, index: index}}, reason}

      {:ok, yaml_map} ->
        {:ok, {:yaml, %{filename: filename, index: index, yaml: yaml_map}}}
    end
  end

  defp create_tests({:error, {:yaml, _}, _} = err), do: [err]

  defp create_tests({:ok, {:yaml, v}}) do
    case Factory.create_tests(v.yaml) do
      {:error, reason} ->
        [{:error, {:yaml, %{filename: v.filename, index: v.index}}, reason}]

      a ->
        Stream.map(a, fn
          {:ok, x} ->
            {:ok, {:data_test, %{filename: v.filename, index: v.index, test: x}}}

          {:error, reason} ->
            {:error, {:data_test, %{filename: v.filename, index: v.index}}, reason}
        end)
    end
  end

  defp execute_test(%__MODULE__{} = ducker, {:ok, {:data_test, _} = v}), do: execute(ducker, v)
  defp execute_test(%__MODULE__{}, {:error, _, _} = err), do: err

  defp execute(%__MODULE__{} = d, {:query, v}) do
    %{query: q, filename: filename, index: idx} = v
    %{conn: conn} = d
    # filename = relative_path(d, filename)

    case Adbc.Connection.query(conn, q) do
      {:ok, _} ->
        {:ok, {:query, %{filename: filename, index: idx}}}

      {:error, reason} ->
        {:error, {:query, %{filename: filename, index: idx}}, reason}
    end
  end

  defp execute(%__MODULE__{} = d, {:data_test, v}) do
    %{test: {name, sql}, filename: filename, index: idx} = v
    %{conn: conn} = d
    # filename = relative_path(d, filename)

    case Adbc.Connection.query(conn, sql) do
      {:ok, _} ->
        {:ok, {:data_test, %{filename: filename, index: idx, name: name}}}

      {:error, reason} ->
        {:error, {:data_test, %{filename: filename, index: idx, name: name}}, reason}
    end
  end

  defp relative_path(%__MODULE__{work_dir: work_dir}, path) do
    Path.relative_to(path, Path.expand(work_dir))
  end

  defp format_result({:ok, {:query, v}}) do
    %{filename: filename, index: idx} = v
    {:ok, "#{filename}: query ##{idx}"}
  end

  defp format_result({:ok, {:data_test, v}}) do
    %{filename: filename, index: idx, name: name} = v
    {:ok, "#{filename}: test suite ##{idx}: #{name}"}
  end

  defp format_result({:error, {:query, v}, reason}) do
    %{filename: filename, index: idx} = v
    {:error, "#{filename}: query ##{idx}", Exception.format_banner(:error, reason)}
  end

  defp format_result({:error, {:yaml, v}, reason}) do
    %{filename: filename, index: idx} = v
    # {:error, "#{filename}: test suite ##{idx}", Exception.format_banner(:error, reason)}
    case reason do
      %{message: message} -> {:error, "#{filename}: test suite ##{idx}", message}
      _ -> {:error, "#{filename}: test suite ##{idx}", reason}
    end
  end

  defp format_result({:error, {:data_test, v}, reason}) do
    %{filename: filename, index: idx, name: name} = v

    case reason do
      %Adbc.Error{} = e ->
        {:error, "#{filename}: test suite ##{idx}: #{name}", Exception.format_banner(:error, e)}

      _ ->
        {:error, "#{filename}: test suite ##{idx}: #{name}",
         Exception.format_banner(:error, reason)}
    end
  end

  @doc """
  Resets the data test result in the database.
  """
  def reset_test_result!(%__MODULE__{} = ducker) do
    Conn.query!(ducker.conn, "DELETE FROM ducker_data_test_result")
  end

  # @doc """
  # Executes all SQL files (.sql) in the given directory.

  # ## Options

  # - `:eex` - If true, EEx is used to evaluate the SQL files.
  # """
  # def execute_query_file_from_dir!(%__MODULE__{} = ducker, dir, opts \\ []) do
  #   eex = Keyword.get(opts, :eex, false)
  #   dir = Path.expand(dir, ducker.work_dir)
  #   bindings = if eex, do: [assigns: [work_dir: ducker.work_dir]], else: nil
  #   filter_fn = Keyword.get(opts, :filter)

  #   with {:ok, files} <-
  #          FileHelper.list_files(dir, ext: ".sql", exclude_hidden: true, filter: filter_fn) do
  #     files
  #     |> Enum.map(fn file -> execute_query_file!(ducker, file, bindings) end)
  #     |> List.flatten()
  #   end
  # end

  # @doc """
  # Executes all data test files (.yaml) in the given directory.

  # ## Options:
  #   - `:filter` - A function to filter files. It should take a file name as an argument and return true or false.
  # """
  # def execute_data_tests_from_dir!(%__MODULE__{} = ducker, dir, opts \\ []) do
  #   dir = Path.expand(dir, ducker.work_dir)

  #   Factory.from_dir(dir, opts)
  #   |> Enum.map(&execute_data_test!(ducker, &1))
  # end

  # def execute_data_tests_from_dir(%__MODULE__{} = ducker, dir, opts \\ []) do
  #   dir = Path.expand(dir, ducker.work_dir)
  #   filter_fn = Keyword.get(opts, :filter)

  #   case FileHelper.list_files(dir, ext: ".yaml", exclude_hidden: true, filter: filter_fn) do
  #     {:ok, files} ->
  #       Enum.map(files, &from_file/1) |> List.flatten()

  #     {:error, reason} ->
  #       raise "failed loading data tests config from #{dir}:\n#{Exception.format_banner(:error, reason)}"
  #   end
  # end

  # defp execute_query_file!(%__MODULE__{} = ducker, file, bindings) do
  #   with {:ok, q_all} <- File.read(file) do
  #     String.split(q_all, "---")
  #     |> Enum.map(fn q -> execute_query!(ducker, file, q, bindings) end)
  #   end
  # end

  # defp execute_query!(%__MODULE__{} = ducker, file, q, nil) do
  #   with {:ok, _} <- Conn.query(ducker.conn, q) do
  #     {:ok, Path.relative_to(file, ducker.work_dir)}
  #   else
  #     {:error, reason} ->
  #       raise "failed executing query from #{Path.relative_to(file, ducker.work_dir)}:\n#{Exception.format_banner(:error, reason)}"
  #   end
  # end

  # defp execute_query!(%__MODULE__{} = ducker, file, q, bindings) do
  #   q =
  #     try do
  #       EEx.eval_string(q, bindings)
  #     rescue
  #       e ->
  #         reraise(
  #           "failed evaluating query from #{Path.relative_to(file, ducker.work_dir)}:\n#{Exception.format_banner(:error, e)}",
  #           __STACKTRACE__
  #         )
  #     end

  #   execute_query!(ducker, file, q, nil)
  # end

  # @doc """
  # Loads data test files from a directory.

  # ## Options:
  #   - `:filter` - A function to filter files. It should take a file name as an argument and return true or false.
  # """
  # def execute_data_tests_from_dir(%__MODULE__{} = ducker, dir, opts \\ []) do
  #   dir = Path.expand(dir, ducker.work_dir)
  #   filter_fn = Keyword.get(opts, :filter)

  #   case FileHelper.list_files(dir, ext: ".yaml", exclude_hidden: true, filter: filter_fn) do
  #     {:ok, files} ->
  #       Enum.map(files, &data_test_from_file/1)
  #       |> List.flatten()
  #       |> Enum.map(&execute_data_test(ducker, &1))

  #     {:error, reason} ->
  #       raise "failed loading data tests spec from #{dir}:\n#{Exception.format_banner(:error, reason)}"
  #   end
  # end

  # def data_test_from_file(filename) do
  #   case YamlElixir.read_from_file(filename) do
  #     {:ok, spec} ->
  #       Factory.create_tests(spec, filename)

  #     {:error, reason} ->
  #       {:error,
  #        "failed parsing data test spec file #{filename}:\n#{Exception.format_banner(:error, reason)}"}
  #   end
  # end

  # defp execute_data_test(%__MODULE__{conn: conn}, {:ok, {name, sql}}) do
  #   case Adbc.Connection.query(conn, sql) do
  #     {:ok, _} ->
  #       {:ok, name}

  #     {:error, reason} ->
  #       {:error, "failed executing test #{name}:\n#{Exception.format_banner(:error, reason)}"}
  #   end
  # end

  # defp execute_data_test(%__MODULE__{conn: _}, {:error, _} = error), do: error

  @doc """
  Create data tests from YAML string
  """
  def data_test_from_string(str) do
    case YamlElixir.read_from_string(str) do
      {:ok, spec} ->
        Factory.create_tests(spec)

      {:error, reason} ->
        raise "failed parsing data test spec:\n#{Exception.format_banner(:error, reason)}"
    end
  end

  defp set_file_search_path!(conn, path) do
    Conn.query!(conn, "SET file_search_path = '#{path}'")
  end

  defp set_work_dir_var!(conn, path) do
    Conn.query!(conn, "SET VARIABLE ducker_work_dir = '#{path}'")
  end
end
