defmodule Ducker.DataTest.Relationship do
  @behaviour Ducker.DataTest

  alias __MODULE__
  alias Ducker.SQLHelper

  defstruct [:file, :table, :fields, :to, :to_fields, :where_clause, :type]

  @impl true
  def create_test_sql(%Relationship{} = v) do
    with {:ok, v} <- validate(v) do
      fields =
        cond do
          is_list(v.fields) -> v.fields
          is_binary(v.fields) -> [v.fields]
        end

      to_fields =
        cond do
          is_nil(v.to_fields) -> fields
          is_list(v.to_fields) -> v.to_fields
          is_binary(v.to_fields) -> [v.to_fields]
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

      %{
        v
        | fields: fields,
          to_fields: to_fields,
          where_clause: where_clause,
          type: type
      }
      |> interpolate_sql()
    end
  end

  defp validate(%Relationship{} = v) do
    cond do
      is_nil(v.table) ->
        {:error, "table is required"}

      is_nil(v.to) ->
        {:error, "to is required"}

      is_nil(v.fields) ->
        {:error, "fields is required"}

      not (is_list(v.fields) or is_binary(v.fields)) ->
        {:error, "fields must be a list or a string"}

      not (is_nil(v.where_clause) or is_list(v.where_clause) or is_binary(v.where_clause)) ->
        {:error, "where is optional butmust be a list or a string"}

      true ->
        {:ok, v}
    end
  end

  defp interpolate_sql(%Relationship{where_clause: nil} = v) do
    {
      "data test #{v.table}: (#{Enum.join(v.fields, ", ")}) -> #{v.to}(#{Enum.join(v.to_fields, ", ")})",
      "ducker_data_test_relationship('#{v.type}', '#{v.table}', [#{v.fields |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}], '#{v.to}', [#{v.to_fields |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}])"
    }
  end

  defp interpolate_sql(%Relationship{} = v) do
    {
      "data test #{v.table}: (#{Enum.join(v.fields, ", ")}) -> #{v.to}(#{Enum.join(v.to_fields, ", ")}) WHERE #{Enum.join(v.where_clause, " AND ")}",
      "ducker_data_test_relationship('#{v.type}', '#{v.table}', [#{v.fields |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}], '#{v.to}', [#{v.to_fields |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}], '#{Enum.join(v.where_clause, " AND ")}')"
    }
  end
end
