defmodule Ducker.DataTest.Relationship do
  @behaviour Ducker.DataTest

  alias __MODULE__
  alias Ducker.SQLHelper

  @enforce_keys [:file, :table, :fields, :to]
  defstruct [:file, :table, :fields, :to, :to_fields, :where_clause, :type]

  @type t :: %__MODULE__{
          file: String.t(),
          table: String.t(),
          fields: String.t() | list(String.t()),
          to: String.t(),
          to_fields: String.t() | list(String.t()),
          where_clause: String.t() | list(String.t()),
          type: String.t()
        }

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
      not (is_list(v.fields) or is_binary(v.fields)) ->
        {:error, "fields must be a list or a string"}

      not (is_nil(v.where_clause) or is_list(v.where_clause) or is_binary(v.where_clause)) ->
        {:error, "where is optional but must be a list or a string"}

      (is_binary(v.fields) and is_list(v.to_fields)) or
          (is_list(v.fields) and is_binary(v.to_fields)) ->
        {:error, "fields and to_fields must have the same length"}

      is_list(v.fields) and is_list(v.to_fields) and length(v.fields) != length(v.to_fields) ->
        {:error, "fields and to_fields must have the same length"}

      true ->
        {:ok, v}
    end
  end

  defp interpolate_sql(%Relationship{where_clause: nil} = v) do
    {:ok,
     {
       "data test #{v.table}: (#{Enum.join(v.fields, ", ")}) -> #{v.to}(#{Enum.join(v.to_fields, ", ")})",
       "ducker_data_test_relationship('#{v.type}', '#{v.table}', [#{v.fields |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}], '#{v.to}', [#{v.to_fields |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}])"
     }}
  end

  defp interpolate_sql(%Relationship{} = v) do
    {:ok,
     {
       "data test #{v.table}: (#{Enum.join(v.fields, ", ")}) -> #{v.to}(#{Enum.join(v.to_fields, ", ")}) WHERE #{Enum.join(v.where_clause, " AND ")}",
       "ducker_data_test_relationship('#{v.type}', '#{v.table}', [#{v.fields |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}], '#{v.to}', [#{v.to_fields |> Enum.map(&"'#{&1}'") |> Enum.join(", ")}], '#{Enum.join(v.where_clause, " AND ")}')"
     }}
  end
end
