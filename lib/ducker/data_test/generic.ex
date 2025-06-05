defmodule Ducker.DataTest.Generic do
  @behaviour Ducker.DataTest

  alias __MODULE__
  alias Ducker.DataTest.Utils

  @enforce_keys [:table, :assert]
  defstruct [:table, :assert, :where_clause, :type]

  @type t :: %__MODULE__{
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
          is_list(v.assert) -> v.assert
          is_binary(v.assert) -> [v.assert]
        end

      where_clause =
        cond do
          is_list(v.where_clause) -> v.where_clause
          is_binary(v.where_clause) -> [v.where_clause]
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
      "#{v.table}: #{Enum.join(v.assert, " AND ")}",
      Utils.wrap_test_sql(
        "ducker_data_test('#{v.type}', '#{v.table}', '#{Enum.map(v.assert, &Utils.escape_single_quotes/1) |> Enum.join(" AND ")}')"
      )
    }
  end

  defp interpolate_sql(%Generic{} = v) do
    {
      "#{v.table}: #{Enum.join(v.assert, " AND ")} WHERE #{Enum.join(v.where_clause, " AND ")}",
      Utils.wrap_test_sql(
        "ducker_data_test('#{v.type}', '#{v.table}', '#{Enum.map(v.assert, &Utils.escape_single_quotes/1) |> Enum.join(" AND ")}', '#{Enum.map(v.where_clause, &Utils.escape_single_quotes/1) |> Enum.join(" AND ")}')"
      )
    }
  end
end
