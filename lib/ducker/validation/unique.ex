defmodule Ducker.Validation.Unique do
  @behaviour Ducker.Validation

  alias __MODULE__
  alias Ducker.SQLHelper

  defstruct [:file, :table, :columns, :where_clause, :type]

  @impl true
  def validate(%Unique{} = v) do
    columns =
      cond do
        is_list(v.columns) -> v.columns
        is_binary(v.columns) -> [v.columns]
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

    %{v | columns: columns, where_clause: where_clause, type: type}
    |> do_validate()
  end

  def do_validate(%Unique{where_clause: nil} = v) do
    {
      "validate #{v.table}: unique(#{Enum.join(v.columns, ", ")})",
      "ducker_validate_unique('#{v.type}', '#{v.table}', [#{v.columns |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}])"
    }
  end

  def do_validate(%Unique{} = v) do
    {
      "validate #{v.table}: unique(#{Enum.join(v.columns, ", ")}) WHERE #{v.where_clause}",
      "ducker_validate_unique('#{v.type}', '#{v.table}', [#{v.columns |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}], '#{Enum.join(v.where_clause, " AND ")}')"
    }
  end
end
