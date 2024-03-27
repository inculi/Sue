defmodule DesuWeb.Live.TrueHome do
  use Phoenix.LiveView

  def render(%{page: "loading"} = assigns) do
    ~L""
  end

  def render(assigns) do
    ~L"""
    <div>
      <span>Nyahallo <%= @name %>!</span>
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
    {:ok, assign(socket, :name, "Robert")}
  end
end
