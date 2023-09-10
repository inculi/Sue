defmodule Sue.DB do
  use GenServer

  require Logger

  alias Sue.DB.Schema
  alias Sue.Models.{Chat, Defn, Poll, Account, Message, PlatformAccount}

  import Subaru, only: [is_dbid: 1]

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

  # TODO: Clean this up. Ideally we should have figured out if we want an edge
  #   or an account ID across all these sorts of calls, and only do that. I also
  #   don't like the naming.
  @doc """
  Try to find Sue Account for Platform Account. If one does not exist, create it.
  Then establish (upsert) an edge between the two and return the Account id.
  """
  @spec link_paccount_to_resolved_user(PlatformAccount.t()) :: Subaru.dbid()
  def link_paccount_to_resolved_user(%PlatformAccount{id: paccount_id})
      when not is_nil(paccount_id) do
    # Find Sue Account for this Platform Account, if not exist we'll create later.
    account_id =
      case Subaru.traverse_one(Schema.ecoll_sue_user_by_platformaccount(), :outbound, paccount_id) do
        {:ok, :dne} ->
          _account_id = Subaru.insert!(%Account{}, Account.collection())

        {:ok, account_doc} ->
          account_doc._id
      end

    {:ok, _} =
      Subaru.upsert_edge(paccount_id, account_id, Schema.ecoll_sue_user_by_platformaccount())

    account_id
  end

  @doc """
  Mark sue accounts as being present in a chat.
  """
  @spec add_user_chat_edge(Account.t(), Chat.t()) :: Subaru.res_id()
  def add_user_chat_edge(%Account{id: account_id}, %Chat{id: chat_id})
      when not is_nil(account_id) and not is_nil(chat_id) do
    Subaru.upsert_edge(account_id, chat_id, Schema.ecoll_sue_user_in_chat())
  end

  # =================
  # || DEFINITIONS ||
  # =================

  @doc """
  Upsert a definition.
  """
  @spec add_defn(Defn.t(), Subaru.dbid(), Subaru.dbid()) :: {:ok, Subaru.dbid()}
  def add_defn(defn, account_id, chat_id) when is_dbid(account_id) and is_dbid(chat_id) do
    defndoc = Defn.doc(defn)
    defncol = Defn.collection()

    d_search = %{var: defn.var, val: defn.val, type: defn.type}

    {:ok, defn_id} = Subaru.upsert(d_search, defndoc, %{}, defncol)
    {:ok, _} = Subaru.upsert_edge(account_id, defn_id, Schema.ecoll_sue_defn_by_user())
    {:ok, _} = Subaru.upsert_edge(chat_id, defn_id, Schema.ecoll_sue_defn_by_chat())

    {:ok, defn_id}
  end

  @doc """
  Search definitions by user.
  """
  @spec get_defns_by_user(Subaru.dbid()) :: [Defn.t()]
  def get_defns_by_user(account_id) when is_dbid(account_id) do
    # only search a depth of one to get adjacent definitions.
    Subaru.traverse!(Schema.ecoll_sue_defn_by_user(), :outbound, account_id, 1, 1)
    |> Enum.map(&Defn.from_doc/1)
  end

  @doc """
  Search definitions by chat.
  """
  @spec get_defns_by_chat(Subaru.dbid()) :: [Defn.t()]
  def get_defns_by_chat(chat_id) when is_dbid(chat_id) do
    # only search a depth of one to get adjacent definitions.
    Subaru.traverse!(Schema.ecoll_sue_defn_by_chat(), :outbound, chat_id, 1, 1)
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
  @spec find_defn(Subaru.dbid(), Subaru.dbid(), bitstring()) :: {:ok, Defn.t()} | {:error, :dne}
  def find_defn(account_id, chat_id, varname)
      when is_dbid(account_id) and is_dbid(chat_id) and is_bitstring(varname) do
    # TODO: add an option to these methods that allows for specifying K
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

  # ===========
  # || POLLS ||
  # ===========
  @spec add_poll(Poll.t(), Subaru.dbid()) :: {:ok, Poll.t()}
  def add_poll(%Poll{chat_id: chat_id} = poll, chat_id) when is_dbid(chat_id) do
    polldoc = Poll.doc(poll)
    pollcol = Poll.collection()

    d_search = %{chat_id: chat_id}
    {:ok, newpoll} = Subaru.upsert_return(d_search, polldoc, %{}, pollcol)
    {:ok, _} = Subaru.upsert_edge(chat_id, newpoll["_id"], Schema.ecoll_sue_poll_by_chat())

    {:ok, Poll.from_doc(newpoll)}
  end

  @spec find_poll(Chat.t()) :: {:ok, Poll.t()} | {:ok, :dne}
  def find_poll(chat) do
    case Subaru.find_one(Poll.collection(), {:==, "x.chat_id", chat.id}) do
      {:ok, doc} when is_map(doc) -> {:ok, Poll.from_doc(doc)}
      {:ok, :dne} -> {:ok, :dne}
    end
  end

  @spec add_poll_vote(Chat.t(), Account.t(), integer()) :: {:ok, Poll.t()}
  def add_poll_vote(chat, account, choice_idx) do
    d_search = %{chat_id: chat.id}

    {:ok, newpoll} =
      Subaru.upsert_return(
        d_search,
        %{},
        %{votes: %{account.id => choice_idx}},
        Poll.collection()
      )

    {:ok, Poll.from_doc(newpoll)}
  end
end
