defmodule DuckerTest do
  use ExUnit.Case
  doctest Ducker

  test "greets the world" do
    assert Ducker.hello() == :world
  end
end
