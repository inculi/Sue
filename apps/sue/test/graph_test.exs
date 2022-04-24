defmodule GraphTest do
  use ExUnit.Case

  # alias Sue.DB.Graph
  # alias Sue.DB.Schema.Vertex
  # alias Sue.Models.{Account, PlatformAccount, Chat, Definition}

  # test "inserts chat relations" do
  #   a1 = %Account{
  #     ref: make_ref(),
  #     name: "a1"
  #   }

  #   a2 = %Account{
  #     ref: make_ref(),
  #     name: "a2"
  #   }

  #   # ---

  #   pa1 = %PlatformAccount{
  #     platform: :imessage,
  #     id: "a1@icloud.com"
  #   }

  #   pa2 = %PlatformAccount{
  #     platform: :imessage,
  #     id: "a2@icloud.com"
  #   }

  #   c = %Chat{
  #     platform: :imessage,
  #     id: 123,
  #     is_direct: false
  #   }

  #   # ---

  #   Graph.add_vertex(a1)
  #   assert Graph.exists?(a1)
  #   Graph.add_vertex(a2)
  #   assert Graph.exists?(a2)
  #   Graph.add_vertex(pa1)
  #   assert Graph.exists?(pa1)
  #   Graph.add_vertex(pa2)
  #   assert Graph.exists?(pa2)
  #   Graph.add_vertex(c)
  #   assert Graph.exists?(c)

  #   Graph.add_bi_edge(c, pa1)
  #   assert Graph.exists_bi_edge?(c, pa1)
  #   Graph.add_bi_edge(c, pa2)
  #   assert Graph.exists_bi_edge?(c, pa2)

  #   Graph.add_bi_edge(pa1, a1)
  #   assert Graph.exists_bi_edge?(pa1, a1)
  #   Graph.add_bi_edge(pa2, a2)
  #   assert Graph.exists_bi_edge?(pa2, a2)

  #   # ---

  #   with [v_res] <- Graph.path(a1, [:platform_account, :chat, :platform_account, :account]) do
  #     assert Vertex.equals?(v_res, a2)
  #   end

  #   with [v_res] <- Graph.path(a2, [:platform_account, :chat, :platform_account, :account]) do
  #     assert Vertex.equals?(v_res, a1)
  #   end

  #   # === DEFINITIONS ===

  #   d1 = %Definition{
  #     ref: make_ref(),
  #     var: "ping",
  #     val: "pong",
  #     kind: :text,
  #     date: DateTime.utc_now()
  #   }

  #   d2 = %Definition{
  #     ref: make_ref(),
  #     var: "megumin",
  #     val: "acute",
  #     kind: :text,
  #     date: DateTime.utc_now()
  #   }

  #   defn_metadata = fn d -> %{kind: d.kind, var: d.var} end

  #   Graph.add_vertex(d1)
  #   Graph.add_vertex(d2)

  #   Graph.add_uni_edge(a1, d1, defn_metadata.(d1))
  #   Graph.add_uni_edge(c, d1, defn_metadata.(d1))

  #   Graph.add_uni_edge(a2, d2, defn_metadata.(d2))
  #   Graph.add_uni_edge(c, d2, defn_metadata.(d2))

  #   with [v_res] <- Graph.adjacent(a1, Vertex.label(Definition), %{kind: :text}) do
  #     assert Vertex.equals?(v_res, d1)
  #   end

  #   with [v_res] <- Graph.adjacent(a1, Vertex.label(Definition), %{var: "ping"}) do
  #     assert Vertex.equals?(v_res, d1)
  #   end

  #   with [v_res] <- Graph.adjacent(a2, Vertex.label(Definition), %{kind: :text}) do
  #     assert Vertex.equals?(v_res, d2)
  #   end

  #   with [v_res] <- Graph.adjacent(a2, Vertex.label(Definition), %{var: "megumin"}) do
  #     assert Vertex.equals?(v_res, d2)
  #   end
  # end

  # test "upsert items" do
  #   # === create Account for a PlatformAccount if it doesn't already exist.

  #   # State 1: neither exists

  #   pa3 = %PlatformAccount{
  #     platform: :imessage,
  #     id: "a3@icloud.com"
  #   }

  #   a3 = %Account{
  #     ref: make_ref(),
  #     name: "a3"
  #   }

  #   Graph.upsert_bi_edge(pa3, a3)

  #   assert Graph.exists?(pa3)
  #   assert Graph.exists?(a3)
  #   assert Graph.exists_bi_edge?(pa3, a3)

  #   with [v_res] <- Graph.adjacent(pa3, Vertex.label(Account)) do
  #     assert Vertex.equals?(v_res, a3)
  #   end

  #   with [v_res] <- Graph.adjacent(a3, Vertex.label(PlatformAccount)) do
  #     assert Vertex.equals?(v_res, pa3)
  #   end

  #   # State 2: PlatformAccount exists

  #   a4 = %Account{
  #     ref: make_ref(),
  #     name: "a4"
  #   }

  #   Graph.getsert_bi_edge_if_unique(pa3, a4)
  #   assert not Graph.exists?(a4)
  #   assert not Graph.exists_bi_edge?(pa3, a4)

  #   pa4 = %PlatformAccount{
  #     platform: :imessage,
  #     id: "a4@icloud.com"
  #   }

  #   # TODO: Test this more thoroughly. Fails when using DB in non-test scenario.
  #   #   (this was before we seperated the test and dev DBs)
  #   Graph.getsert_bi_edge_if_unique(pa4, a4)
  #   assert Graph.exists?(a4)
  #   assert Graph.exists_bi_edge?(pa4, a4)
  # end
end
