defmodule DuckerTest.DataTest.Generic do
  import Ducker, only: [data_test_from_string: 1]
  alias Ducker.DataTest.Utils
  use ExUnit.Case, async: true

  describe "Generic Data Test" do
    test "single assertion" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - assert: field1 > 0
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: field1 > 0",
                  Utils.wrap_test_sql("ducker_data_test('error', 'some_table', 'field1 > 0')")
                }}
    end

    test "single assertion with single quote" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - assert: field1 LIKE '%hello%'
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: field1 LIKE '%hello%'",
                  Utils.wrap_test_sql(
                    "ducker_data_test('error', 'some_table', 'field1 LIKE ''%hello%''')"
                  )
                }}
    end

    test "multiple assertions" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - assert:
                - field1 > 0
                - field2 > 10
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: field1 > 0 AND field2 > 10",
                  Utils.wrap_test_sql(
                    "ducker_data_test('error', 'some_table', 'field1 > 0 AND field2 > 10')"
                  )
                }}
    end

    test "multiple assertions with single quote" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - assert:
                - field1 LIKE '%hello%'
                - field2 LIKE '%world%'
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: field1 LIKE '%hello%' AND field2 LIKE '%world%'",
                  Utils.wrap_test_sql(
                    "ducker_data_test('error', 'some_table', 'field1 LIKE ''%hello%'' AND field2 LIKE ''%world%''')"
                  )
                }}
    end

    test "where clause" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - assert: field1 > 0
              where: field2 IS NOT NULL
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: field1 > 0 WHERE field2 IS NOT NULL",
                  Utils.wrap_test_sql(
                    "ducker_data_test('error', 'some_table', 'field1 > 0', 'field2 IS NOT NULL')"
                  )
                }}
    end

    test "where clause with single quote" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - assert: field1 > 0
              where: field2 LIKE '%hello%'
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: field1 > 0 WHERE field2 LIKE '%hello%'",
                  Utils.wrap_test_sql(
                    "ducker_data_test('error', 'some_table', 'field1 > 0', 'field2 LIKE ''%hello%''')"
                  )
                }}
    end

    test "multiple where clause" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - assert: field1 > 0
              where:
              - field2 IS NOT NULL
              - field3 > 10
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: field1 > 0 WHERE field2 IS NOT NULL AND field3 > 10",
                  Utils.wrap_test_sql(
                    "ducker_data_test('error', 'some_table', 'field1 > 0', 'field2 IS NOT NULL AND field3 > 10')"
                  )
                }}
    end

    test "custom test type" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - assert: field1 > 0
              type: warn
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: field1 > 0",
                  Utils.wrap_test_sql("ducker_data_test('warn', 'some_table', 'field1 > 0')")
                }}
    end
  end
end
