defmodule DuckerTest.DataTest.Unique do
  alias Ducker.DataTest.Config
  use ExUnit.Case, async: true

  describe "Unique Data Test" do
    test "single field" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - unique: field1
        """)

      assert Enum.at(cfg, 0) == {
               "data test some_table: unique(field1)",
               "ducker_data_test_unique('error', 'some_table', ['field1'])"
             }
    end

    test "multiple fields" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - unique:
                - field1
                - field2
        """)

      assert Enum.at(cfg, 0) == {
               "data test some_table: unique(field1, field2)",
               "ducker_data_test_unique('error', 'some_table', ['field1', 'field2'])"
             }
    end

    test "single where clause" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - unique: field1
              where: field2 > 0
        """)

      assert Enum.at(cfg, 0) == {
               "data test some_table: unique(field1) WHERE field2 > 0",
               "ducker_data_test_unique('error', 'some_table', ['field1'], 'field2 > 0')"
             }
    end

    test "single where clause with single quote" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - unique: field1
              where: field2 LIKE '%hello%'
        """)

      assert Enum.at(cfg, 0) == {
               "data test some_table: unique(field1) WHERE field2 LIKE ''%hello%''",
               "ducker_data_test_unique('error', 'some_table', ['field1'], 'field2 LIKE ''%hello%''')"
             }
    end

    test "multiple where clauses" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - unique: field1
              where:
              - field2 IS NOT NULL
              - field3 > 10
        """)

      assert Enum.at(cfg, 0) == {
               "data test some_table: unique(field1) WHERE field2 IS NOT NULL AND field3 > 10",
               "ducker_data_test_unique('error', 'some_table', ['field1'], 'field2 IS NOT NULL AND field3 > 10')"
             }
    end

    test "multiple where clauses with single quote" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - unique: field1
              where:
              - field2 LIKE '%hello%'
              - field3 LIKE '%world%'
        """)

      assert Enum.at(cfg, 0) == {
               "data test some_table: unique(field1) WHERE field2 LIKE ''%hello%'' AND field3 LIKE ''%world%''",
               "ducker_data_test_unique('error', 'some_table', ['field1'], 'field2 LIKE ''%hello%'' AND field3 LIKE ''%world%''')"
             }
    end

    test "custom test type" do
      cfg =
        Config.from_string("""
          table: some_table
          data_tests:
            - unique: field1
              type: warn
        """)

      assert Enum.at(cfg, 0) == {
               "data test some_table: unique(field1)",
               "ducker_data_test_unique('warn', 'some_table', ['field1'])"
             }
    end
  end
end
