defmodule DuckerTest.FileHelper do
  alias Ducker.FileHelper

  use ExUnit.Case

  test "list all files in directory" do
    l = FileHelper.list_files("test/fixtures")

    assert l ==
             {:ok,
              [
                ".hidden.sql",
                ".hidden.yaml",
                "001_test.csv",
                "001_test.sql",
                "001_test.yaml",
                "002_test.csv",
                "002_test.sql",
                "002_test.yaml",
                "003_test.sql"
              ]}
  end

  test "list all files in directory excluding hidden files" do
    l = FileHelper.list_files("test/fixtures", exclude_hidden: true)

    assert l ==
             {:ok,
              [
                "001_test.csv",
                "001_test.sql",
                "001_test.yaml",
                "002_test.csv",
                "002_test.sql",
                "002_test.yaml",
                "003_test.sql"
              ]}
  end

  test "list files in directory using filter" do
    l =
      FileHelper.list_files("test/fixtures",
        filter: fn x -> String.starts_with?(x, "001") end
      )

    assert l ==
             {:ok,
              [
                "001_test.csv",
                "001_test.sql",
                "001_test.yaml"
              ]}
  end

  test "list files in directory and filter by extension" do
    l =
      FileHelper.list_files("test/fixtures", ext: ".sql")

    assert l ==
             {:ok,
              [
                ".hidden.sql",
                "001_test.sql",
                "002_test.sql",
                "003_test.sql"
              ]}
  end

  test "error when directory does not exist" do
    l = FileHelper.list_files("nonexistent_directory")

    assert l == {:error, "directory not found: nonexistent_directory"}
  end
end
