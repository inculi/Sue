defmodule Sue.New.Schema do
  alias Sue.New.{Account, Chat, Defn}

  @spec vertex_collections() :: [bitstring()]
  def vertex_collections() do
    defined_vertices() ++ []
  end

  @spec edge_collections() :: [bitstring()]
  def edge_collections() do
    ["sue_user_in_chat", "sue_defn_by_user", "sue_defn_by_chat"]
  end

  # TODO: It would be really nice if there was a way to auto-register these
  #   when creating them to begin with.
  defp defined_vertices() do
    [
      Account.collection(),
      Chat.collection(),
      Defn.collection()
    ]
  end
end
