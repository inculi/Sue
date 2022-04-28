defmodule SubaruTest do
  use ExUnit.Case
  doctest Subaru

  test "create and delete collections" do
    {:ok, _} = Subaru.DB.create_collection("mycollection", :doc)
    {:ok, _} = Subaru.DB.remove_collection("mycollection")
    {:error, :dne} = Subaru.DB.remove_collection("augh")
  end

  test "query" do
    Subaru.DB.remove_collection("mycollection")
    {:ok, _} = Subaru.DB.create_collection("mycollection", :doc)
    {:ok, id} = Subaru.insert(%{"name" => "Sue", "swaglevel" => 9001}, "mycollection")

    expr = {:and, {:==, "x.name", "Sue"}, {:==, "x.swaglevel", 9001}}
    {:ok, doc} = Subaru.find_one("mycollection", expr)
    assert id == doc["_id"]

    emptyres_expr = {:and, {:==, "x.name", "Sue"}, {:==, "x.swaglevel", 0}}
    {:ok, :dne} = Subaru.find_one("mycollection", emptyres_expr)

    {:ok, _} = Subaru.DB.remove_collection("mycollection")
  end
end
