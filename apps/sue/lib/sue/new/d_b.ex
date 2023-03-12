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
  Mark users as being present in a chat.
  """
  def add_user_chat_edge(user_id, chat_id) do
    Subaru.upsert_edge(user_id, chat_id, "sue_user_in_chat")
  end

  # =================
  # || DEFINITIONS ||
  # =================

  @doc """
  Upsert a definition.
  """
  @spec add_defn(Defn.t(), Subaru.dbid(), Subaru.dbid()) :: {:ok, Subaru.dbid()}
  def add_defn(defn, account_id, chat_id) do
    defndoc = Defn.doc(defn)
    defncol = Defn.collection()

    d_search = %{var: defn.var, val: defn.val, type: defn.type}

    {:ok, defn_id} = Subaru.upsert(d_search, defndoc, %{}, defncol)
    {:ok, _} = Subaru.upsert_edge(account_id, defn_id, "sue_defn_by_user")
    {:ok, _} = Subaru.upsert_edge(chat_id, defn_id, "sue_defn_by_chat")

    {:ok, defn_id}
  end

  @doc """
  Search definitions by user.
  """
  @spec get_defns_by_user(Subaru.dbid()) :: [Defn.t()]
  def get_defns_by_user(account_id) do
    # only search a depth of one to get adjacent definitions.
    Subaru.traverse!("sue_defn_by_user", :outbound, account_id, 1, 1)
    |> Enum.map(&Defn.from_doc/1)
  end

  @doc """
  Search definitions by chat.
  """
  @spec get_defns_by_chat(Subaru.dbid()) :: [Defn.t()]
  def get_defns_by_chat(chat_id) do
    # only search a depth of one to get adjacent definitions.
    Subaru.traverse!("sue_defn_by_chat", :outbound, chat_id, 1, 1)
    |> Enum.map(&Defn.from_doc/1)
  end

  @doc """
  Important: There are multiple possible algorithms we can use to resolve which
    definition a user is looking for when they call for it. Most of the time,
    these definitions represent inside jokes for a user group. Thus, it is
    useful for defns to be group (chat) writable.

  For now, the logic is this:
    If a user is chatting 1-1 with Sue: return the user's personal value.
    If a user is chatting in a group: return the last modified v for that k
      owned by any user in the chat group.
  """
  @spec search_defn(Subaru.dbid(), Subaru.dbid(), binary()) :: {:ok, Defn.t()} | {:error, :dne}
  def search_defn(account_id, chat_id, varname) do
    pass1 = get_defns_by_user(account_id)
    pass2 = get_defns_by_chat(chat_id)

    hits =
      (pass1 ++ pass2)
      |> Enum.filter(fn d -> d.var == varname end)
      |> Enum.uniq_by(fn d -> d.id end)
      |> Enum.sort_by(fn d -> d.date_modified end, :desc)

    case hits do
      [] -> {:error, :dne}
      [best | _others] -> {:ok, best}
    end
  end

  def debug_clear_collections() do
    for vc <- Schema.vertex_collections() do
      Subaru.remove_all(vc)
    end

    for ec <- Schema.edge_collections() do
      Subaru.remove_all(ec)
    end
  end
end
