defmodule SubaruTest do
  use ExUnit.Case
  doctest Subaru

  test "greets the world" do
    assert Subaru.hello() == :world
  end
end
