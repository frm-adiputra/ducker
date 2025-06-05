defmodule Ducker.FileHelper do
  @doc """
  Lists files in a directory (sorted). By default, hidden files are included.

  ## Options:
    - `:exclude_hidden` - If true, hidden files (starting with ".") are not included.
    - `:ext` - If provided, only files with this extension are included.
    - `:filter` - A function to filter files. It should take a file name as an argument and return true or false.
  """
  def list_files(path, opts \\ []) do
    with {:ok, files} <- File.ls(path) do
      exclude_hidden = Keyword.get(opts, :exclude_hidden, false)
      ext = Keyword.get(opts, :ext)

      filter_fn =
        case Keyword.get(opts, :filter) do
          nil -> fn _ -> true end
          v -> v
        end

      {
        :ok,
        files
        |> may_exclude_hidden(exclude_hidden)
        |> may_filter_ext(ext)
        |> Enum.filter(filter_fn)
        |> Enum.sort()
        # |> Enum.map(fn file -> Path.join(path, file) end)
      }
    else
      {:error, :enoent} ->
        {:error, "directory not found: #{path}"}
    end
  end

  defp may_exclude_hidden(files, false), do: files

  defp may_exclude_hidden(files, true) do
    Enum.filter(files, fn file -> not String.starts_with?(file, ".") end)
  end

  defp may_filter_ext(files, nil), do: files

  defp may_filter_ext(files, ext) do
    Enum.filter(files, fn file -> String.ends_with?(file, ext) end)
  end
end
