defmodule DuckerTest.FileHelper do
  alias Ducker.FileHelper

  use ExUnit.Case

  test "list all files in directory" do
    l = FileHelper.list_files("test/fixtures")

    assert l ==
             {:ok,
              [
                "test/fixtures/.hidden.sql",
                "test/fixtures/.hidden.yaml",
                "test/fixtures/001_test.csv",
                "test/fixtures/001_test.sql",
                "test/fixtures/001_test.yaml",
                "test/fixtures/002_test.csv",
                "test/fixtures/002_test.sql",
                "test/fixtures/002_test.yaml"
              ]}
  end

  test "list all files in directory excluding hidden files" do
    l = FileHelper.list_files("test/fixtures", exclude_hidden: true)

    assert l ==
             {:ok,
              [
                "test/fixtures/001_test.csv",
                "test/fixtures/001_test.sql",
                "test/fixtures/001_test.yaml",
                "test/fixtures/002_test.csv",
                "test/fixtures/002_test.sql",
                "test/fixtures/002_test.yaml"
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
                "test/fixtures/001_test.csv",
                "test/fixtures/001_test.sql",
                "test/fixtures/001_test.yaml"
              ]}
  end

  test "list files in directory and filter by extension" do
    l =
      FileHelper.list_files("test/fixtures", ext: ".sql")

    assert l ==
             {:ok,
              [
                "test/fixtures/.hidden.sql",
                "test/fixtures/001_test.sql",
                "test/fixtures/002_test.sql"
              ]}
  end

  test "error when directory does not exist" do
    l = FileHelper.list_files("nonexistent_directory")

    assert l == {:error, "directory not found: nonexistent_directory"}
  end
end
