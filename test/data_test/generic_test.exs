defmodule DuckerTest.DataTest.Generic do
  alias Ducker.DataTest.Config
  use ExUnit.Case, async: true

  describe "Generic Data Test" do
    test "single assertion" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - assert: field1 > 0
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "data test some_table: field1 > 0",
                  "ducker_data_test('error', 'some_table', 'field1 > 0')"
                }}
    end

    test "single assertion with single quote" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - assert: field1 LIKE '%hello%'
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "data test some_table: field1 LIKE ''%hello%''",
                  "ducker_data_test('error', 'some_table', 'field1 LIKE ''%hello%''')"
                }}
    end

    test "multiple assertions" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - assert:
                - field1 > 0
                - field2 > 10
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "data test some_table: field1 > 0 AND field2 > 10",
                  "ducker_data_test('error', 'some_table', 'field1 > 0 AND field2 > 10')"
                }}
    end

    test "multiple assertions with single quote" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - assert:
                - field1 LIKE '%hello%'
                - field2 LIKE '%world%'
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "data test some_table: field1 LIKE ''%hello%'' AND field2 LIKE ''%world%''",
                  "ducker_data_test('error', 'some_table', 'field1 LIKE ''%hello%'' AND field2 LIKE ''%world%''')"
                }}
    end

    test "where clause" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - assert: field1 > 0
              where: field2 IS NOT NULL
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "data test some_table: field1 > 0 WHERE field2 IS NOT NULL",
                  "ducker_data_test('error', 'some_table', 'field1 > 0', 'field2 IS NOT NULL')"
                }}
    end

    test "where clause with single quote" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - assert: field1 > 0
              where: field2 LIKE '%hello%'
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "data test some_table: field1 > 0 WHERE field2 LIKE ''%hello%''",
                  "ducker_data_test('error', 'some_table', 'field1 > 0', 'field2 LIKE ''%hello%''')"
                }}
    end

    test "multiple where clause" do
      cfg =
        Config.from_string("""
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
                  "data test some_table: field1 > 0 WHERE field2 IS NOT NULL AND field3 > 10",
                  "ducker_data_test('error', 'some_table', 'field1 > 0', 'field2 IS NOT NULL AND field3 > 10')"
                }}
    end

    test "custom test type" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - assert: field1 > 0
              type: warn
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "data test some_table: field1 > 0",
                  "ducker_data_test('warn', 'some_table', 'field1 > 0')"
                }}
    end
  end
end
