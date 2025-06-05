defmodule DuckerTest.DataTest.Utils do
  alias Ducker.DataTest.Utils
  use ExUnit.Case, async: true

  test "wrap_test_sql" do
    assert Utils.wrap_test_sql("any sql") == """
           INSERT OR REPLACE INTO ducker_data_test_result FROM (
             SELECT * FROM
             any sql
           )
           """
  end
end
