defmodule DuckerTest.DataTest.Config do
  alias Ducker.DataTest.Config
  use ExUnit.Case, async: true

  describe "Data Test Config" do
    test "invalid configuration" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - fields: field1
              type: warn
        """)

      assert {:error, _} = Enum.at(cfg, 0)
    end
  end
end
