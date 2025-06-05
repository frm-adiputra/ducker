defmodule DuckerTest.DataTest.Relationship do
  import Ducker, only: [data_test_from_string: 1]
  alias Ducker.DataTest.Utils
  use ExUnit.Case, async: true

  describe "Relationship Data Test" do
    test "single field" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - to: other_table
              fields: field1
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: (field1) -> other_table(field1)",
                  Utils.wrap_test_sql(
                    "ducker_data_test_relationship('error', 'some_table', ['field1'], 'other_table', ['field1'])"
                  )
                }}
    end

    test "single field with different name" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - to: other_table
              fields: field1
              to_fields: field3
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: (field1) -> other_table(field3)",
                  Utils.wrap_test_sql(
                    "ducker_data_test_relationship('error', 'some_table', ['field1'], 'other_table', ['field3'])"
                  )
                }}
    end

    test "multiple fields" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
          - to: other_table
            fields:
              - field1
              - field2
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: (field1, field2) -> other_table(field1, field2)",
                  Utils.wrap_test_sql(
                    "ducker_data_test_relationship('error', 'some_table', ['field1', 'field2'], 'other_table', ['field1', 'field2'])"
                  )
                }}
    end

    test "multiple fields different names" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
          - to: other_table
            fields:
              - field1
              - field2
            to_fields:
              - field3
              - field4
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: (field1, field2) -> other_table(field3, field4)",
                  Utils.wrap_test_sql(
                    "ducker_data_test_relationship('error', 'some_table', ['field1', 'field2'], 'other_table', ['field3', 'field4'])"
                  )
                }}
    end

    test "single where clause" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - to: other_table
              fields: field1
              where: field2 > 0
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: (field1) -> other_table(field1) WHERE field2 > 0",
                  Utils.wrap_test_sql(
                    "ducker_data_test_relationship('error', 'some_table', ['field1'], 'other_table', ['field1'], 'field2 > 0')"
                  )
                }}
    end

    test "single where clause with single quote" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - to: other_table
              fields: field1
              where: field2 LIKE '%hello%'
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: (field1) -> other_table(field1) WHERE field2 LIKE '%hello%'",
                  Utils.wrap_test_sql(
                    "ducker_data_test_relationship('error', 'some_table', ['field1'], 'other_table', ['field1'], 'field2 LIKE ''%hello%''')"
                  )
                }}
    end

    test "multiple where clauses" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - to: other_table
              fields: field1
              where:
                - field2 IS NOT NULL
                - field3 > 10
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: (field1) -> other_table(field1) WHERE field2 IS NOT NULL AND field3 > 10",
                  Utils.wrap_test_sql(
                    "ducker_data_test_relationship('error', 'some_table', ['field1'], 'other_table', ['field1'], 'field2 IS NOT NULL AND field3 > 10')"
                  )
                }}
    end

    test "multiple where clauses with single quote" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - to: other_table
              fields: field1
              where:
                - field2 LIKE '%hello%'
                - field3 LIKE '%world%'
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: (field1) -> other_table(field1) WHERE field2 LIKE '%hello%' AND field3 LIKE '%world%'",
                  Utils.wrap_test_sql(
                    "ducker_data_test_relationship('error', 'some_table', ['field1'], 'other_table', ['field1'], 'field2 LIKE ''%hello%'' AND field3 LIKE ''%world%''')"
                  )
                }}
    end

    test "custom test type" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - to: other_table
              fields: field1
              type: warn
        """)

      assert Enum.at(cfg, 0) ==
               {:ok,
                {
                  "some_table: (field1) -> other_table(field1)",
                  Utils.wrap_test_sql(
                    "ducker_data_test_relationship('warn', 'some_table', ['field1'], 'other_table', ['field1'])"
                  )
                }}
    end

    test "invalid: fields and to_fields must have the same length" do
      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - to: other_table
              fields:
                - field1
                - field2
              to_fields:
                - field3
                - field4
                - field5
        """)

      assert {:error, "fields and to_fields must have the same length"} == Enum.at(cfg, 0)

      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - to: other_table
              fields: field1
              to_fields:
                - field3
                - field4
                - field5
        """)

      assert {:error, "fields and to_fields must have the same length"} == Enum.at(cfg, 0)

      cfg =
        data_test_from_string("""
          table: some_table
          data_tests:
            - to: other_table
              fields:
                - field1
                - field2
              to_fields: field3
        """)

      assert {:error, "fields and to_fields must have the same length"} == Enum.at(cfg, 0)
    end
  end
end
