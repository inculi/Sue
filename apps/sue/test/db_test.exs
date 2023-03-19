defmodule DBTest do
  use ExUnit.Case

  alias Sue.New.DB
  alias Sue.New.{Account, Chat, Defn}
  alias Sue.Models.Poll
  alias Sue.New.Schema

  # TODO: Figure out if there's a way to limit the scope of a DB change to each
  #   test, or at least maybe automatically call clear_collections at the
  #   beginning and end of each test.

  test "defns" do
    Schema.debug_clear_collections()

    d = Defn.new("megumin", "acute", :text)

    a = mock_account()

    c = mock_chat()

    # upsert should prevent this from duplicating.
    {:ok, defn_id1} = DB.add_defn(d, a.id, c.id)
    {:ok, defn_id2} = DB.add_defn(d, a.id, c.id)
    [defn] = DB.get_defns_by_user(a.id)

    {:ok, defn_searched} = DB.search_defn(a.id, c.id, "megumin")

    assert defn_id1 == defn_id2
    assert defn_id1 == defn.id
    assert defn.id == defn_searched.id
  end

  test "users" do
    Schema.debug_clear_collections()

    a1 =
      Account.resolve(%Account{
        name: "Robert",
        handle: "mwlp",
        platform_id: {:telegram, 100}
      })

    a2 =
      Account.resolve(%Account{
        name: "William",
        handle: "epicpug",
        platform_id: {:telegram, 101}
      })

    a3 =
      Account.resolve(%Account{
        name: "James",
        handle: "jaykm",
        platform_id: {:telegram, 102}
      })

    c1 =
      Chat.resolve(%Chat{
        platform_id: {:telegram, 200},
        is_direct: false
      })

    c2 =
      Chat.resolve(%Chat{
        platform_id: {:telegram, 201},
        is_direct: false
      })

    # Robert and William are in Chat 1
    {:ok, _} = DB.add_user_chat_edge(a1.id, c1.id)
    {:ok, _} = DB.add_user_chat_edge(a2.id, c1.id)

    # William and James are in Chat 2
    {:ok, _} = DB.add_user_chat_edge(a2.id, c2.id)
    {:ok, _} = DB.add_user_chat_edge(a3.id, c2.id)
  end

  test "polls" do
    Schema.debug_clear_collections()

    a = mock_account()
    c = mock_chat()
    p = Poll.new(c, "Best movie?", ["TRON Legacy", "Wild Tales", "Whiplash"], :standard)

    {:ok, poll_id} = DB.add_poll(p, c.id)
    {:ok, new_poll} = DB.add_poll_vote(c, a, 0)

    assert true
  end

  defp mock_account() do
    Account.resolve(%Account{
      name: "Robert",
      handle: "mwlp",
      platform_id: {:debug, 100}
    })
  end

  defp mock_chat() do
    Chat.resolve(%Chat{
      platform_id: {:debug, 200},
      is_direct: false
    })
  end
end
