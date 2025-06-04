defmodule Ducker.DataTest.Generic do
  @behaviour Ducker.DataTest

  alias __MODULE__
  alias Ducker.SQLHelper

  @enforce_keys [:file, :table, :assert]
  defstruct [:file, :table, :assert, :where_clause, :type]

  @type t :: %__MODULE__{
          file: String.t(),
          table: String.t(),
          assert: String.t() | list(String.t()),
          where_clause: String.t() | list(String.t()),
          type: String.t()
        }

  @impl true
  def create_test_sql(%Generic{} = v) do
    with {:ok, v} <- validate(v) do
      assert =
        cond do
          is_list(v.assert) -> Enum.map(v.assert, &SQLHelper.escape_single_quotes/1)
          is_binary(v.assert) -> [SQLHelper.escape_single_quotes(v.assert)]
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

      {:ok,
       interpolate_sql(%{
         v
         | assert: assert,
           where_clause: where_clause,
           type: type
       })}
    end
  end

  defp validate(%Generic{} = v) do
    cond do
      not (is_list(v.assert) or is_binary(v.assert)) ->
        {:error, "assert must be a list or a string"}

      not (is_nil(v.where_clause) or is_list(v.where_clause) or is_binary(v.where_clause)) ->
        {:error, "where is optional but must be a list or a string"}

      true ->
        {:ok, v}
    end
  end

  defp interpolate_sql(%Generic{where_clause: nil} = v) do
    {
      "data test #{v.table}: #{Enum.join(v.assert, " AND ")}",
      "ducker_data_test('#{v.type}', '#{v.table}', '#{Enum.join(v.assert, " AND ")}')"
    }
  end

  defp interpolate_sql(%Generic{} = v) do
    {
      "data test #{v.table}: #{Enum.join(v.assert, " AND ")} WHERE #{Enum.join(v.where_clause, " AND ")}",
      "ducker_data_test('#{v.type}', '#{v.table}', '#{Enum.join(v.assert, " AND ")}', '#{Enum.join(v.where_clause, " AND ")}')"
    }
  end
end
