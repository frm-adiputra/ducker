defmodule DuckerTest do
  use ExUnit.Case

  setup do
    db = start_supervised!({Adbc.Database, driver: :duckdb})
    conn = start_supervised!({Adbc.Connection, database: db})
    %{conn: conn}
  end

  test "execute_query_from_dir", %{conn: conn} do
    ducker = Ducker.new!(conn, "test/fixtures")

    found = Ducker.execute_query_from_dir(ducker, ".")
    assert length(found) == 4
    assert Enum.at(found, 0) == {:ok, "001_test.sql: query #1"}
    assert Enum.at(found, 1) == {:ok, "002_test.sql: query #1"}
    assert {:error, "003_test.sql: query #1", _} = Enum.at(found, 2)
    assert Enum.at(found, 3) == {:ok, "003_test.sql: query #2"}
  end
end
