defmodule DuckerTest do
  use ExUnit.Case

  setup do
    db = start_supervised!({Adbc.Database, driver: :duckdb})
    conn = start_supervised!({Adbc.Connection, database: db})
    %{conn: conn}
  end

  test "execute_query_from_dir", %{conn: conn} do
    ducker = Ducker.new!(conn, "test/fixtures")

    found = Ducker.execute_query_from_dir(ducker, ".", eex: true)
    assert length(found) == 6
    assert Enum.at(found, 0) == {:ok, "001_test.sql: query #1"}
    assert Enum.at(found, 1) == {:ok, "001_test.sql: query #2"}
    assert {:error, "001_test.sql: query #3", _} = Enum.at(found, 2)
    assert Enum.at(found, 3) == {:ok, "002_test.sql: query #1"}
    assert {:error, "003_test.sql: query #1", _} = Enum.at(found, 4)
    assert Enum.at(found, 5) == {:ok, "003_test.sql: query #2"}
  end

  test "execute_test_from_dir", %{conn: conn} do
    ducker = Ducker.new!(conn, "test/fixtures")

    Ducker.execute_query_from_dir(ducker, ".")
    found = Ducker.execute_test_from_dir(ducker, ".")
    # IO.inspect(found)

    # assert Ducker.execute_test_from_dir(ducker, ".") == {:ok}
    assert length(found) == 7

    assert Enum.at(found, 0) == {:ok, "001_test.yaml: test suite #1: mtcars: unique(model)"}

    assert Enum.at(found, 1) ==
             {:ok, "001_test.yaml: test suite #1: mtcars: mpg > 0 WHERE model Like '%Ford%'"}

    assert Enum.at(found, 2) == {:error, "001_test.yaml: test suite #2", "invalid specification"}
    assert Enum.at(found, 3) == {:error, "001_test.yaml: test suite #3", "malformed yaml"}
    assert Enum.at(found, 4) == {:ok, "002_test.yaml: test suite #1: mtcars_color: unique(model)"}

    assert Enum.at(found, 5) ==
             {:ok,
              "002_test.yaml: test suite #1: mtcars_color: color IN ('red', 'blue', 'green')"}

    assert {:error, "002_test.yaml: test suite #1: mtcars_color: invalid IS NULL", _} =
             Enum.at(found, 6)
  end
end
