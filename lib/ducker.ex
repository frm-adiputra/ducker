defmodule Ducker do
  @moduledoc """
  Documentation for `Ducker`.
  """

  defstruct [:conn, :work_dir]
  alias Adbc.Connection, as: Conn
  alias Ducker.FileHelper
  alias Ducker.Validation
  alias Ducker.Validation.Config

  @doc """
  Initializes a Ducker struct with a connection and work directory.
  """
  def initialize!(conn, work_dir) do
    ducker = %Ducker{conn: conn, work_dir: work_dir}
    execute_query_file_from_dir!(ducker, :code.priv_dir(:ducker))

    set_file_search_path!(conn, work_dir)
    set_work_dir_var!(conn, work_dir)
    ducker
  end

  @doc """
  Resets the validation results in the database.
  """
  def reset_validation_results!(%Ducker{} = ducker) do
    Conn.query!(ducker.conn, "DELETE FROM ducker_validate_result")
  end

  @doc """
  Executes all SQL files (.sql) in the given directory.

  ## Options

  - `:eex` - If true, EEx is used to evaluate the SQL files.
  """
  def execute_query_file_from_dir!(%Ducker{} = ducker, dir, opts \\ []) do
    eex = Keyword.get(opts, :eex, false)
    dir = Path.expand(dir, ducker.work_dir)
    bindings = if eex, do: [assigns: [work_dir: ducker.work_dir]], else: nil
    filter_fn = Keyword.get(opts, :filter)

    with {:ok, files} <-
           FileHelper.list_files(dir, ext: ".sql", exclude_hidden: true, filter: filter_fn) do
      files
      |> Enum.map(fn file -> execute_query_file!(ducker, file, bindings) end)
      |> List.flatten()
    end
  end

  @doc """
  Executes all validation files (.yaml) in the given directory.

  ## Options:
    - `:filter` - A function to filter files. It should take a file name as an argument and return true or false.
  """
  def execute_validation_from_dir!(%Ducker{} = ducker, dir, opts \\ []) do
    dir = Path.expand(dir, ducker.work_dir)

    Config.from_dir(dir, opts)
    |> Enum.map(&execute_validation!(ducker, &1))
  end

  defp execute_validation!(%Ducker{} = ducker, v) do
    case Validation.do_validate(ducker, v) do
      {:ok, _} ->
        {name, _} = v
        {:ok, name}

      {:error, reason} ->
        raise reason
    end
  end

  defp execute_query_file!(%Ducker{} = ducker, file, bindings) do
    with {:ok, q_all} <- File.read(file) do
      String.split(q_all, "---")
      |> Enum.map(fn q -> execute_query!(ducker, file, q, bindings) end)
    end
  end

  defp execute_query!(%Ducker{} = ducker, file, q, nil) do
    with {:ok, _} <- Conn.query(ducker.conn, q) do
      {:ok, Path.relative_to(file, ducker.work_dir)}
    else
      {:error, reason} ->
        raise "failed executing query from #{Path.relative_to(file, ducker.work_dir)}:\n#{Exception.format_banner(:error, reason)}"
    end
  end

  defp execute_query!(%Ducker{} = ducker, file, q, bindings) do
    q =
      try do
        EEx.eval_string(q, bindings)
      rescue
        e ->
          reraise(
            "failed evaluating query from #{Path.relative_to(file, ducker.work_dir)}:\n#{Exception.format_banner(:error, e)}",
            __STACKTRACE__
          )
      end

    execute_query!(ducker, file, q, nil)
  end

  defp set_file_search_path!(conn, path) do
    Conn.query!(conn, "SET file_search_path = '#{path}'")
  end

  defp set_work_dir_var!(conn, path) do
    Conn.query!(conn, "SET VARIABLE ducker_work_dir = '#{path}'")
  end
end
