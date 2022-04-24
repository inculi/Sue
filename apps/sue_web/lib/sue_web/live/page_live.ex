defmodule SueWeb.PageLive do
  use SueWeb, :live_view

  alias Sue.DB

  @impl true
  def mount(_params, _session, socket) do
    table_defns = DB.Schema.Vertex.label(Sue.Models.Definition)

    definitions =
      DB.match!({table_defns, :_, :_})
      |> Enum.map(fn {^table_defns, _key, val} -> val end)

    {:ok,
     assign(socket,
       definitions: definitions
     )}
  end
end
