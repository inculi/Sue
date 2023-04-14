defmodule Sue.DB.Schema do
  alias Sue.Models.Poll
  alias Sue.Models.{Account, Chat, Defn}

  @spec vertex_collections() :: [bitstring()]
  def vertex_collections() do
    defined_vertices() ++ []
  end

  @spec edge_collections() :: [bitstring()]
  def edge_collections() do
    [
      "sue_user_in_chat",
      "sue_defn_by_user",
      "sue_defn_by_chat",
      "sue_poll_by_chat",
      "sue_user_by_platformaccount"
    ]
  end

  # TODO: It would be really nice if there was a way to auto-register these
  #   when creating them to begin with.
  defp defined_vertices() do
    [
      Account.collection(),
      Chat.collection(),
      Defn.collection(),
      Poll.collection(),
      "sue_platformaccounts"
    ]
  end

  def debug_clear_collections() do
    for vc <- vertex_collections() do
      Subaru.remove_all(vc)
    end

    for ec <- edge_collections() do
      Subaru.remove_all(ec)
    end
  end
end
