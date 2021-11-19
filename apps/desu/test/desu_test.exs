defmodule DesuTest do
  use ExUnit.Case
  doctest Desu

  test "greets the world" do
    assert Desu.hello() == :world
  end
end
