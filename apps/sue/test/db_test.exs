defmodule DBTest do
  use ExUnit.Case

  alias Sue.New.DB
  alias Sue.New.{Account, Chat, Defn}
  alias Sue.New.Schema

  test "defns" do
    clear_collections()

    d = Defn.new("megumin", "acute", :text)

    a =
      Account.resolve(%Account{
        name: "Robert",
        handle: "tomboysweat",
        platform_id: {"telegram", 100}
      })

    c =
      Chat.resolve(%Chat{
        platform_id: {"telegram", 200},
        is_direct: false
      })

    # upsert should prevent this from duplicating.
    {:ok, defn_id1} = DB.add_defn(d, a.id, c.id)
    {:ok, defn_id2} = DB.add_defn(d, a.id, c.id)

    {:ok, [defn]} = DB.get_defns_by_user(a.id)

    assert defn_id1 == defn_id2
    assert defn_id1 == defn["_id"]
  end

  test "users" do
    clear_collections()

    a1 =
      Account.resolve(%Account{
        name: "Robert",
        handle: "tomboysweat",
        platform_id: {"telegram", 100}
      })

    a2 =
      Account.resolve(%Account{
        name: "William",
        handle: "epicpug",
        platform_id: {"telegram", 101}
      })

    a3 =
      Account.resolve(%Account{
        name: "James",
        handle: "jaykm",
        platform_id: {"telegram", 102}
      })

    c1 =
      Chat.resolve(%Chat{
        platform_id: {"telegram", 200},
        is_direct: false
      })

    c2 =
      Chat.resolve(%Chat{
        platform_id: {"telegram", 201},
        is_direct: false
      })

    # Robert and William are in Chat 1
    {:ok, _} = DB.add_user_chat_edge(a1.id, c1.id)
    {:ok, _} = DB.add_user_chat_edge(a2.id, c1.id)

    # William and James are in Chat 2
    {:ok, _} = DB.add_user_chat_edge(a2.id, c2.id)
    {:ok, _} = DB.add_user_chat_edge(a3.id, c2.id)
  end

  defp clear_collections() do
    for vc <- Schema.vertex_collections() do
      Subaru.remove_all(vc)
    end

    for ec <- Schema.edge_collections() do
      Subaru.remove_all(ec)
    end
  end
end
