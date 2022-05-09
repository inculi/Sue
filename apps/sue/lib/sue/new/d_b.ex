defmodule Sue.New.DB do
  use GenServer

  require Logger

  alias Sue.New.Schema
  alias Sue.New.Defn

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    init_schema()

    {:ok, []}
  end

  # initialize the collections that need to be in our db for sue.
  defp init_schema() do
    for vcolname <- Schema.vertex_collections() do
      Subaru.DB.create_collection(vcolname, :doc)
    end

    for ecolname <- Schema.edge_collections() do
      Subaru.DB.create_collection(ecolname, :edge)
    end
  end

  @doc """
  Upsert a definition.
  """
  @spec add_defn(Defn.t(), Subaru.dbid(), Subaru.dbid()) :: Subaru.dbid()
  def add_defn(defn, account_id, chat_id) do
    defndoc = Defn.doc(defn)
    defncol = Defn.collection()

    d_search = %{var: defn.var, val: defn.val, type: defn.type}

    {:ok, defn_id} = Subaru.upsert(d_search, defndoc, %{}, defncol)
    {:ok, _} = Subaru.upsert_edge(account_id, defn_id, "sue_defn_by_user")
    {:ok, _} = Subaru.upsert_edge(chat_id, defn_id, "sue_defn_by_chat")

    {:ok, defn_id}
  end

  def get_defns_by_user(account_id) do
    Subaru.traverse("sue_defn_by_user", :outbound, account_id, 1, 1)
  end

  def add_user_chat_edge(user_id, chat_id) do
    Subaru.upsert_edge(user_id, chat_id, "sue_user_in_chat")
  end
end
