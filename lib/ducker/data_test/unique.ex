defmodule Ducker.DataTest.Unique do
  @behaviour Ducker.DataTest

  alias __MODULE__
  alias Ducker.SQLHelper

  @enforce_keys [:file, :table, :fields]
  defstruct [:file, :table, :fields, :where_clause, :type]

  @type t :: %__MODULE__{
          file: String.t(),
          table: String.t(),
          fields: String.t() | list(String.t()),
          where_clause: String.t() | list(String.t()),
          type: String.t()
        }

  @impl true
  def create_test_sql(%Unique{} = v) do
    with {:ok, v} <- validate(v) do
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

      {:ok, interpolate_sql(%{v | fields: fields, where_clause: where_clause, type: type})}
    end
  end

  defp validate(%Unique{} = v) do
    cond do
      not (is_list(v.fields) or is_binary(v.fields)) ->
        {:error, "fields must be a list or a string"}

      not (is_nil(v.where_clause) or is_list(v.where_clause) or is_binary(v.where_clause)) ->
        {:error, "where is optional but must be a list or a string"}

      true ->
        {:ok, v}
    end
  end

  defp interpolate_sql(%Unique{where_clause: nil} = v) do
    {
      "data test #{v.table}: unique(#{Enum.join(v.fields, ", ")})",
      "ducker_data_test_unique('#{v.type}', '#{v.table}', [#{v.fields |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}])"
    }
  end

  defp interpolate_sql(%Unique{} = v) do
    {
      "data test #{v.table}: unique(#{Enum.join(v.fields, ", ")}) WHERE #{Enum.join(v.where_clause, " AND ")}",
      "ducker_data_test_unique('#{v.type}', '#{v.table}', [#{v.fields |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}], '#{Enum.join(v.where_clause, " AND ")}')"
    }
  end
end
