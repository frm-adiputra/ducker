defmodule Ducker.Validation.Reference do
  @behaviour Ducker.Validation

  alias __MODULE__
  alias Ducker.SQLHelper

  defstruct [:file, :table, :columns, :reference, :foreign_columns, :where_clause, :type]

  @impl true
  def validate(%Reference{} = v) do
    columns =
      cond do
        is_list(v.columns) -> v.columns
        is_binary(v.columns) -> [v.columns]
      end

    foreign_columns =
      cond do
        is_nil(v.foreign_columns) -> columns
        is_list(v.foreign_columns) -> v.foreign_columns
        is_binary(v.foreign_columns) -> [v.foreign_columns]
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
      | columns: columns,
        foreign_columns: foreign_columns,
        where_clause: where_clause,
        type: type
    }
    |> do_validate()
  end

  def do_validate(%Reference{where_clause: nil} = v) do
    {
      "validate #{v.table}: (#{Enum.join(v.columns, ", ")}) -> #{v.reference}(#{Enum.join(v.foreign_columns, ", ")})",
      "ducker_validate_reference('#{v.type}', '#{v.table}', [#{v.columns |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}], '#{v.reference}', [#{v.foreign_columns |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}])"
    }
  end

  def do_validate(%Reference{} = v) do
    {
      "validate #{v.table}: (#{Enum.join(v.columns, ", ")}) -> #{v.reference}(#{Enum.join(v.foreign_columns, ", ")}) WHERE #{v.where_clause}",
      "ducker_validate_reference('#{v.type}', '#{v.table}', [#{v.columns |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}], '#{v.reference}', [#{v.foreign_columns |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}], '#{Enum.join(v.where_clause, " AND ")}')"
    }
  end
end
