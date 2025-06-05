defmodule Ducker.DataTest.Utils do
  def wrap_test_sql(sql) do
    """
    INSERT OR REPLACE INTO ducker_data_test_result FROM (
      SELECT * FROM
      #{sql}
    )
    """
  end

  @doc """
  Escapes single quotes in a string for SQL queries.
  """
  def escape_single_quotes(str) do
    String.replace(str, "'", "''")
  end
end
