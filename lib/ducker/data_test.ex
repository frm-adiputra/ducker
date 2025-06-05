defmodule Ducker.DataTest do
  @moduledoc """
  Data tests are specified using a YAML file with the following structure:

  ```yaml
  table: <table_name>
  data_tests:
    - assert: <expression>
      where: <where_clause>
      type: <type>
    - unique: [<column1>, <column2>, ...]
      where: <where_clause>
      type: <type>
    - to: <table_name>
      where: <where_clause>
      fields: [<column1>, <column2>, ...]
      to_fields: [<column1>, <column2>, ...]
      type: <type>
  ```
  """

  @enforce_keys [:name, :sql]
  defstruct [:name, :sql]

  @type t :: %__MODULE__{name: String.t(), sql: String.t()}

  @callback create_test_sql(config :: map) ::
              {:ok, {name :: String.t(), sql :: String.t()}} | {:error, reason :: String.t()}

  # @spec run_test(%Ducker{conn: Adbc.Connection.t()}, {name :: String.t(), sql :: String.t()}) ::
  #         {:ok, name :: String.t()} | {:error, reason :: String.t()}
  # def run_test(%Ducker{conn: conn}, {name, sql}) do
  #   q = """
  #   INSERT OR REPLACE INTO ducker_data_test_result FROM (
  #     SELECT * FROM
  #     #{sql}
  #   )
  #   """

  #   case Adbc.Connection.query(conn, q) do
  #     {:ok, _} ->
  #       {:ok, name}

  #     {:error, reason} ->
  #       {:error, "failed executing test #{name}:\n#{Exception.format_banner(:error, reason)}"}
  #   end
  # end
end
