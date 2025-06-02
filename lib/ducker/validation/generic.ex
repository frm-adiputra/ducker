defmodule Ducker.Validation.Generic do
  @behaviour Ducker.Validation

  alias __MODULE__
  alias Ducker.SQLHelper

  defstruct [:file, :table, :expression, :where_clause, :type]

  @impl true
  def validate(%Generic{expression: expression} = v) when is_binary(expression) do
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
      | expression: SQLHelper.escape_single_quotes(v.expression),
        where_clause: where_clause,
        type: type
    }
    |> do_validate()
  end

  def do_validate(%Generic{where_clause: nil} = v) do
    {
      "validate #{v.table}: #{v.expression}",
      "ducker_validate('#{v.type}', '#{v.table}', '#{v.expression}')"
    }
  end

  def do_validate(%Generic{} = v) do
    {
      "validate #{v.table}: #{v.expression} WHERE #{v.where_clause}",
      "ducker_validate('#{v.type}', '#{v.table}', '#{v.expression}', '#{Enum.join(v.where_clause, " AND ")}')"
    }
  end
end
