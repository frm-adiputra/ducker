defmodule DuckerTest.DataTest.Factory do
  import Ducker, only: [data_test_from_string: 1]
  use ExUnit.Case, async: true

  describe "Data Test Factory" do
    test "invalid configuration" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - fields: field1
              type: warn
        """)

      assert {:error, _} = Enum.at(cfg, 0)
    end
  end
end
