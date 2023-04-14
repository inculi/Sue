defmodule DesuWeb.Live.Home do
  use Phoenix.LiveView

  def render(%{page: "loading"} = assigns) do
    ~L""
  end

  def render(assigns) do
    ~L"""
    <div>
      <span>You drew a <%= @wonderweapon %> from the box!</span>
    </div>
    """
  end

  def mount(params, session, socket) do
    case connected?(socket) do
      true -> connected_mount(params, session, socket)
      false -> {:ok, assign(socket, page: "loading")}
    end
  end

  defp connected_mount(_params, _session, socket) do
    ww = ["Ray Gun", "Wunderwaffe", "Thunder Gun"] |> Enum.random()
    {:ok, assign(socket, :wonderweapon, ww)}
  end
end
