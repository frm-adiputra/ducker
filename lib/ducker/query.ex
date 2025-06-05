defmodule Ducker.Query do
  # def execute_from_dir(%Ducker{} = ducker, dir, opts \\ []) do
  #   eex = Keyword.get(opts, :eex, false)
  #   dir = Path.expand(dir, ducker.work_dir)
  #   bindings = if eex, do: [assigns: [work_dir: ducker.work_dir]], else: nil
  #   filter_fn = Keyword.get(opts, :filter)

  #   with {:ok, files} <-
  #          FileHelper.list_files(dir, ext: ".sql", exclude_hidden: true, filter: filter_fn) do
  #     files
  #     |> Stream.map(fn file -> execute_query_file(ducker, file, bindings) end)
  #     |> List.flatten()
  #   end
  # end

  # def from_file(file, bindings) do
  #   # Implementation here
  # end

  # # ---

  # defp execute_query_file(%Ducker{} = ducker, file, bindings) do
  #   with {:ok, content} <- File.read(file) do
  #     String.split(content, "---")
  #     |> Stream.with_index(fn x, i -> {i, x} end)
  #     |> Stream.map(fn {i, x} ->
  #       case eval_query(x, bindings) do
  #         {:error, reason} ->
  #           {i, {:error, "error evaluating query ##{i + 1} from file `#{file}`: #{reason}"}}

  #         any ->
  #           {i, any}
  #       end
  #     end)
  #     |> Stream.map(fn {i, x} ->
  #       with {:ok, q} <- x,
  #            {:ok, _} <- Ducker.execute_query(ducker, q) do
  #         {:ok, "#{file}: query ##{i + 1}"}
  #       else
  #         {:error, reason} ->
  #           {:error, "error executing query ##{i + 1} from file `#{file}`: #{reason}"}
  #       end
  #     end)
  #   end
  # end

  # defp parse_query(%Ducker{} = ducker, query, bindings) do
  #   with {:ok, q} <- File.read(query) do
  #     String.split(q, "---")
  #     |> Enum.map(fn q -> execute_query(ducker, query, q, bindings) end)
  #   end
  # end

  def eval_query(query, nil), do: {:ok, query}

  def eval_query(query, bindings) do
    try do
      {:ok, EEx.eval_string(query, bindings, parser_options: [emit_warnings: false])}
      # quoted = EEx.compile_string(query)
      # {result, _bindings} = Code.eval_quoted(quoted, bindings)
      # {:ok, result}
    rescue
      e ->
        {:error, e}
        # reraise(
        #   "failed evaluating query from #{Path.relative_to(filename, ducker.work_dir)}:\n#{Exception.format_banner(:error, e)}",
        #   __STACKTRACE__
        # )
    end
  end

  # defp execute_query_file(%Ducker{} = ducker, file, bindings) do
  #   with {:ok, q_all} <- File.read(file) do
  #     String.split(q_all, "---")
  #     |> Enum.map(fn q -> execute_query(ducker, file, q, bindings) end)
  #   end
  # end

  # defp execute_query!(%Ducker{} = ducker, file, q, nil) do
  #   with {:ok, _} <- Conn.query(ducker.conn, q) do
  #     {:ok, Path.relative_to(file, ducker.work_dir)}
  #   else
  #     {:error, reason} ->
  #       raise "failed executing query from #{Path.relative_to(file, ducker.work_dir)}:\n#{Exception.format_banner(:error, reason)}"
  #   end
  # end

  # defp execute_query!(%Ducker{} = ducker, file, q, bindings) do
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
end
