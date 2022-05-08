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

  test "edges" do
    {:ok, _} = Subaru.DB.create_collection("vtuber_talents", :doc)
    {:ok, _} = Subaru.DB.create_collection("vtuber_agencies", :doc)
    {:ok, _} = Subaru.DB.create_collection("vtuber_talent_agency_contracts", :edge)

    # create vtuber talents
    {:ok, gura} = Subaru.insert(%{name: "Gura", subscribers: 3_940_000}, "vtuber_talents")
    {:ok, ame} = Subaru.insert(%{name: "Ame", subscribers: 1_650_000}, "vtuber_talents")
    {:ok, roa} = Subaru.insert(%{name: "Roa", subscribers: 353_000}, "vtuber_talents")

    # create vtuber agencies
    {:ok, hololive} = Subaru.insert(%{name: "Hololive", country: "JP"}, "vtuber_agencies")
    {:ok, nijisanji} = Subaru.insert(%{name: "Nijisanji", country: "JP"}, "vtuber_agencies")

    # link talents to agencies
    Subaru.insert_edge(gura, hololive, "vtuber_talent_agency_contracts")
    Subaru.insert_edge(ame, hololive, "vtuber_talent_agency_contracts")
    Subaru.insert_edge(roa, nijisanji, "vtuber_talent_agency_contracts")

    # confirm we can find what we added
    {:ok, verts} = Subaru.traverse("vtuber_talent_agency_contracts", :any, hololive)
    assert Enum.any?(verts, fn x -> x["_id"] == ame end)
    assert Enum.any?(verts, fn x -> x["_id"] == gura end)

    # cleanup
    {:ok, _} = Subaru.DB.remove_collection("vtuber_talents")
    {:ok, _} = Subaru.DB.remove_collection("vtuber_agencies")
    {:ok, _} = Subaru.DB.remove_collection("vtuber_talent_agency_contracts")
  end
end
