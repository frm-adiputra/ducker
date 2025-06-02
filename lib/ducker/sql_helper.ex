defmodule Ducker.SQLHelper do
  @doc """
  Escapes single quotes in a string for SQL queries.
  """
  def escape_single_quotes(str) do
    String.replace(str, "'", "''")
  end
end
