defmodule Subaru do
  alias Subaru.{DB, Vertex}

  def insert_v!(v) do
    DB.insert(
      Vertex.doc(v),
      Vertex.collection(v)
    )
  end

  def get_defns() do
    "
FOR defn_i IN sue_defnAuthor
  FOR defn_j IN sue_defnChat
    FILTER defn_i.to == defn_j.to
    RETURN defn_i.to
    "
    |> String.trim()
    |> DB.debug_exec(%{}, read: ["sue_defnAuthor", "sue_defnChat"])
  end
end
