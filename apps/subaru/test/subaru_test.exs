defmodule SubaruTest do
  use ExUnit.Case
  doctest Subaru

  alias Subaru.Query

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

  test "exists" do
    {:ok, _} = Subaru.DB.create_collection("chats", :doc)
    {:ok, _nash} = Subaru.insert(%{name: "Nash Ramblers"}, "chats")

    # Confirm exists
    expr = {:==, "x.name", "Nash Ramblers"}
    assert Subaru.exists?("chats", expr) == true

    # Confirm does not exist.
    expr2 = {:==, "x.name", "piranha"}
    assert Subaru.exists?("chats", expr2) == false
    {:ok, _} = Subaru.DB.remove_collection("chats")
  end

  test "hypothetical" do
    {:ok, _} = Subaru.DB.create_collection("paccounts", :doc)
    {:ok, _} = Subaru.DB.create_collection("accounts", :doc)
    {:ok, _} = Subaru.DB.create_collection("account_by_paccount", :edge)

    a = %{platform: "telegram", id: 123}
    b = %{platform: "imessage", id: 456}
    c = %{platform: "discord", id: 789}

    {:ok, telegram_account} = Subaru.upsert(a, a, %{}, "paccounts")
    {:ok, imessage_account} = Subaru.upsert(b, b, %{}, "paccounts")
    {:ok, discord_account} = Subaru.upsert(c, c, %{}, "paccounts")

    desu_metadata = %{name: "Miko"}
    {:ok, desu_account} = Subaru.upsert(desu_metadata, desu_metadata, %{}, "accounts")

    Subaru.upsert_edge(telegram_account, desu_account, "account_by_paccount")
    Subaru.upsert_edge(imessage_account, desu_account, "account_by_paccount")
    Subaru.upsert_edge(discord_account, desu_account, "account_by_paccount")

    {:ok, [%{"_id" => ^desu_account}]} =
      Subaru.traverse("account_by_paccount", :outbound, telegram_account)

    assert Subaru.traverse!("account_by_paccount", :inbound, desu_account) |> length() == 3

    Subaru.DB.remove_collection("paccounts")
    Subaru.DB.remove_collection("accounts")
    Subaru.DB.remove_collection("account_by_paccount")
  end

  test "hypothetical2" do
    {platform, id} = {:imessage, 123}

    doc = %{platform: platform, id: id}
    doc_search = doc
    doc_insert = doc

    Query.new()
  end
end
