defmodule DBTest do
  use ExUnit.Case

  alias Sue.New.{Account, Chat}

  test "confirm subaru genserver is accessible" do
    assert Subaru.DB.ping() == :pong
  end

  # test "insert" do
  #   init_db()

  #   a1 = %Account{
  #     name: "Megumin Swagbucks",
  #     handle: "mswagbucks",
  #     platform_id: {"imessage", 1}
  #   }

  #   c1 = %Chat{platform_id: {"imessage", 1}, is_direct: false}

  #   a1_id = Subaru.insert(a1)
  #   c1_id = Subaru.insert(c1)
  #   e1_id = Subaru.insert_edge(a1_id, c1_id, "sue_inChat")

  #   # Subaru.find_one("sue_inChat", {:==, "x._from", c1_id})
  #   |> IO.puts()

  #   assert true
  # end

  # def init_db() do
  #   :ok = Subaru.remove_all("sue_users")
  #   :ok = Subaru.remove_all("sue_chats")
  #   :ok = Subaru.remove_all("sue_inChat")

  #   Subaru.DB.create_collection("sue_users", :doc)
  #   Subaru.DB.create_collection("sue_chats", :doc)
  #   Subaru.DB.create_collection("sue_inChat", :edge)
  # end
end
