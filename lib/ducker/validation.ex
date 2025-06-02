defmodule Ducker.Validation do
  @moduledoc """
  Validation is specified using a YAML file with the following structure:

  ```yaml
  table: <table_name>
  validations:
    - validate: <expression>
      where: <where_clause>
      type: <type>
    - unique: [<column1>, <column2>, ...]
      where: <where_clause>
      type: <type>
    - reference: <table_name>
      where: <where_clause>
      columns: [<column1>, <column2>, ...]
      foreign_columns: [<column1>, <column2>, ...]
  ```
  """
  @callback validate(config :: map()) :: {name :: binary(), sql :: binary()}

  def do_validate(%Ducker{conn: conn}, {name, sql}) do
    q = """
    INSERT OR REPLACE INTO ducker_validate_result FROM (
      SELECT * FROM
      #{sql}
    )
    """

    case Adbc.Connection.query(conn, q) do
      {:ok, _} ->
        {:ok, name}

      {:error, reason} ->
        {:error,
         "failed executing validation #{name}:\n#{Exception.format_banner(:error, reason)}"}
    end
  end
end
