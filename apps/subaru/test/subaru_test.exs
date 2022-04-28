defmodule SubaruTest do
  use ExUnit.Case
  doctest Subaru

  test "create and delete collections" do
    {:ok, _} = Subaru.DB.create_collection("mycollection", :doc)
    {:ok, _} = Subaru.DB.remove_collection("mycollection")
    {:error, :dne} = Subaru.DB.remove_collection("augh")
  end

  test "insert" do
    {:ok, _} = Subaru.DB.create_collection("mycollection", :doc)

    # insert
    {:ok, id} = Subaru.insert(%{"name" => "Sue", "swaglevel" => 9001}, "mycollection")

    # find_one and compare
    expr = {:and, {:==, "x.name", "Sue"}, {:==, "x.swaglevel", 9001}}
    {:ok, doc} = Subaru.find_one("mycollection", expr)
    assert id == doc["_id"]

    # purposefully empty find_one
    emptyres_expr = {:and, {:==, "x.name", "Sue"}, {:==, "x.swaglevel", 0}}
    {:ok, :dne} = Subaru.find_one("mycollection", emptyres_expr)

    {:ok, _} = Subaru.DB.remove_collection("mycollection")
  end

  test "upsert" do
    {:ok, _} = Subaru.DB.create_collection("mycollection", :doc)

    # upsert a user. searching by (platform, id) tells us if they exist already.
    {platform, id} = {:telegram, 123}
    doc_search = %{platform: platform, id: id}
    doc = %{platform: platform, id: id, name: "Sue", handle: "ImSueBot"}

    {:ok, id} = Subaru.upsert(doc_search, doc, %{}, "mycollection")

    # search and assert if we were successful.
    expr = {:and, {:==, "x.name", "Sue"}, {:==, "x.handle", "ImSueBot"}}
    {:ok, doc} = Subaru.find_one("mycollection", expr)

    assert id == doc["_id"]

    {:ok, _} = Subaru.DB.remove_collection("mycollection")
  end
end
