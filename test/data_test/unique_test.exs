defmodule DuckerTest.DataTest.Unique do
  import Ducker, only: [data_test_from_string: 1]
  alias Ducker.DataTest.Utils
  use ExUnit.Case, async: true

  describe "Unique Data Test" do
    test "single field" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - unique: field1
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: unique(field1)",
                  Utils.wrap_test_sql(
                    "ducker_data_test_unique('error', 'some_table', ['field1'])"
                  )
                }}
    end

    test "multiple fields" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - unique:
                - field1
                - field2
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: unique(field1, field2)",
                  Utils.wrap_test_sql(
                    "ducker_data_test_unique('error', 'some_table', ['field1', 'field2'])"
                  )
                }}
    end

    test "single where clause" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - unique: field1
              where: field2 > 0
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: unique(field1) WHERE field2 > 0",
                  Utils.wrap_test_sql(
                    "ducker_data_test_unique('error', 'some_table', ['field1'], 'field2 > 0')"
                  )
                }}
    end

    test "single where clause with single quote" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - unique: field1
              where: field2 LIKE '%hello%'
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: unique(field1) WHERE field2 LIKE '%hello%'",
                  Utils.wrap_test_sql(
                    "ducker_data_test_unique('error', 'some_table', ['field1'], 'field2 LIKE ''%hello%''')"
                  )
                }}
    end

    test "multiple where clauses" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - unique: field1
              where:
              - field2 IS NOT NULL
              - field3 > 10
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: unique(field1) WHERE field2 IS NOT NULL AND field3 > 10",
                  Utils.wrap_test_sql(
                    "ducker_data_test_unique('error', 'some_table', ['field1'], 'field2 IS NOT NULL AND field3 > 10')"
                  )
                }}
    end

    test "multiple where clauses with single quote" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - unique: field1
              where:
              - field2 LIKE '%hello%'
              - field3 LIKE '%world%'
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: unique(field1) WHERE field2 LIKE '%hello%' AND field3 LIKE '%world%'",
                  Utils.wrap_test_sql(
                    "ducker_data_test_unique('error', 'some_table', ['field1'], 'field2 LIKE ''%hello%'' AND field3 LIKE ''%world%''')"
                  )
                }}
    end

    test "custom test type" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - unique: field1
              type: warn
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: unique(field1)",
                  Utils.wrap_test_sql("ducker_data_test_unique('warn', 'some_table', ['field1'])")
                }}
    end
  end
end
