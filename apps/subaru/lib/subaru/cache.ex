defmodule Subaru.Cache do
  use GenServer

  @table_userchats :user_chat_edges_cache

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    state = %{}
    {:ok, state}
  end

  def add!(table, key, val) do
    Cachex.put!(table, key, val)
  end

  def exists?(table, key) do
    {:ok, res} = Cachex.exists?(table, key)
    res
  end
end
