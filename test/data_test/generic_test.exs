defmodule DuckerTest.DataTest.Generic do
  alias Ducker.DataTest.Config
  use ExUnit.Case, async: true

  describe "Generic Data Test" do
    test "expression" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - test: field1 > 0
        """)

      assert Enum.at(cfg, 0) == {
               "data test some_table: field1 > 0",
               "ducker_data_test('error', 'some_table', 'field1 > 0')"
             }
    end

    test "expression with single quote" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - test: field1 LIKE '%hello%'
        """)

      assert Enum.at(cfg, 0) == {
               "data test some_table: field1 LIKE ''%hello%''",
               "ducker_data_test('error', 'some_table', 'field1 LIKE ''%hello%''')"
             }
    end

    test "where clause" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - test: field1 > 0
              where: field2 IS NOT NULL
        """)

      assert Enum.at(cfg, 0) == {
               "data test some_table: field1 > 0 WHERE field2 IS NOT NULL",
               "ducker_data_test('error', 'some_table', 'field1 > 0', 'field2 IS NOT NULL')"
             }
    end

    test "where clause with single quote" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - test: field1 > 0
              where: field2 LIKE '%hello%'
        """)

      assert Enum.at(cfg, 0) == {
               "data test some_table: field1 > 0 WHERE field2 LIKE ''%hello%''",
               "ducker_data_test('error', 'some_table', 'field1 > 0', 'field2 LIKE ''%hello%''')"
             }
    end

    test "multiple where clause" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - test: field1 > 0
              where:
              - field2 IS NOT NULL
              - field3 > 10
        """)

      assert Enum.at(cfg, 0) == {
               "data test some_table: field1 > 0 WHERE field2 IS NOT NULL AND field3 > 10",
               "ducker_data_test('error', 'some_table', 'field1 > 0', 'field2 IS NOT NULL AND field3 > 10')"
             }
    end

    test "custom test type" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - test: field1 > 0
              type: warn
        """)

      assert Enum.at(cfg, 0) == {
               "data test some_table: field1 > 0",
               "ducker_data_test('warn', 'some_table', 'field1 > 0')"
             }
    end
  end
end
