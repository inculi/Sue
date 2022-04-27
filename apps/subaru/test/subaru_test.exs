defmodule SubaruTest do
  use ExUnit.Case
  doctest Subaru

  test "create and delete collections" do
    Subaru.DB.create_collection("mycollection", :doc)
    Subaru.DB.remove_collection("mycollection")
    Subaru.DB.remove_collection("augh")

    assert true
  end
end
