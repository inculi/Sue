defmodule Sue.DB.Schema do
  @moduledoc """
  Used to define the types of elements (vertices) in our graph.
  Some of these are connected by edges:
    Chat     <-> PlatformAccount <-> Chat
    Account   -> Definition
    Chat      -> Definition
  Some of these are left disconnected, and function simply as normal tables:
    Poll
  """
  alias Sue.Models.{Account, PlatformAccount, Chat, Poll, Definition}

  defmodule Vertex do
    alias __MODULE__
    @type t() :: Account.t() | PlatformAccount.t() | Chat.t() | Definition.t() | Poll.t()
    @type module_name_t() :: Account | PlatformAccount | Chat | Definition | Poll
    @type tuple_t() :: {atom(), any()}

    @spec id(Vertex.t()) :: any()
    def id(v) do
      case v do
        %Account{} -> v.ref
        %PlatformAccount{} -> {v.platform, v.id}
        %Chat{} -> {v.platform, v.id}
        %Definition{} -> v.ref
        %Poll{} -> v.chat
      end
    end

    @spec label(Vertex.t() | module_name_t()) :: atom()
    def label(v_module) when is_atom(v_module) do
      case v_module do
        Account -> :account
        PlatformAccount -> :platform_account
        Chat -> :chat
        Definition -> :defn
        Poll -> :poll
      end
    end

    def label(vstruct) do
      label(vstruct.__struct__)
    end

    @doc """
    Compare two vertices (either as their struct forms, or {type, id} tuples).
    """
    @spec equals?(__MODULE__.t() | {atom(), any()}, __MODULE__.t() | {atom(), any()}) :: boolean()
    def equals?({v1_type, v1_id}, {v2_type, v2_id}) do
      v1_type == v2_type and v1_id == v2_id
    end

    def equals?({v1_type, v1_id}, v2) do
      v1_type == label(v2) and v1_id == id(v2)
    end

    def equals?(v1, {v2_type, v2_id}) do
      label(v1) == v2_type and id(v1) == v2_id
    end

    def equals?(v1, v2) do
      label(v1) == label(v2) and id(v1) == id(v2)
    end
  end

  # Public API
  @spec vtypes :: [Vertex.module_name_t()]
  def vtypes() do
    [
      Account,
      PlatformAccount,
      Chat,
      Definition,
      Poll
    ]
  end

  def tables() do
    graph_tables =
      for vtype <- vtypes() do
        table_name = Vertex.label(vtype)
        table_opts = [type: :set, attributes: [:key, :val]]
        {table_name, table_opts}
      end ++
        [
          {:edges,
           [
             type: :bag,
             attributes: [:srctype, :dsttype, :srcid, :dstid, :metadata],
             index: [:dsttype, :srcid, :dstid]
           ]}
        ]

    kv_tables = [
      {:state, kv_opts()}
    ]

    graph_tables ++ kv_tables
  end

  defp kv_opts(), do: [type: :set, attributes: [:key, :val]]
end
