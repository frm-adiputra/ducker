defmodule Ducker.DataTest.Unique do
  @behaviour Ducker.DataTest

  alias __MODULE__
  alias Ducker.SQLHelper

  defstruct [:file, :table, :fields, :where_clause, :type]

  @impl true
  def create_test_sql(%Unique{} = v) do
    fields =
      cond do
        is_list(v.fields) -> v.fields
        is_binary(v.fields) -> [v.fields]
      end

    where_clause =
      cond do
        is_list(v.where_clause) -> Enum.map(v.where_clause, &SQLHelper.escape_single_quotes/1)
        is_binary(v.where_clause) -> [SQLHelper.escape_single_quotes(v.where_clause)]
        is_nil(v.where_clause) -> nil
      end

    type =
      cond do
        is_nil(v.type) -> "error"
        true -> v.type
      end

    %{v | fields: fields, where_clause: where_clause, type: type}
    |> interpolate_sql()
  end

  def interpolate_sql(%Unique{where_clause: nil} = v) do
    {
      "data test #{v.table}: unique(#{Enum.join(v.fields, ", ")})",
      "ducker_data_test_unique('#{v.type}', '#{v.table}', [#{v.fields |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}])"
    }
  end

  def interpolate_sql(%Unique{} = v) do
    {
      "data test #{v.table}: unique(#{Enum.join(v.fields, ", ")}) WHERE #{Enum.join(v.where_clause, " AND ")}",
      "ducker_data_test_unique('#{v.type}', '#{v.table}', [#{v.fields |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}], '#{Enum.join(v.where_clause, " AND ")}')"
    }
  end
end
