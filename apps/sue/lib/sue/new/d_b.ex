defmodule Sue.New.DB do
  def add_v(vertex, coll) do
    vertex
    |> Map.from_struct()
    |> Map.drop([:id])
    |> Subaru.DB.insert(coll)
  end
end
