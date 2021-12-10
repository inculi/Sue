defmodule Sue.Models.Definition do
  @enforce_keys [:ref, :var, :val, :kind, :date]
  defstruct [:ref, :var, :val, :kind, :date]

  @type t() :: %__MODULE__{
          ref: reference(),
          var: String.t(),
          val: String.t(),
          kind: :text | :data | :lambda,
          date: DateTime.t()
        }

  @defn_label Sue.DB.Schema.Vertex.label(__MODULE__)

  require Logger

  alias __MODULE__
  alias Sue.DB
  alias Sue.Models.{Account, Chat, PlatformAccount}

  def set(var, val, :text = kind, chat, account) do
    d = %Definition{
      ref: make_ref(),
      var: var,
      val: val,
      kind: kind,
      date: DateTime.utc_now()
    }

    metadata = %{kind: kind, var: var}

    DB.Graph.add_vertex(d)
    DB.Graph.add_uni_edge(chat, d, metadata)
    DB.Graph.add_uni_edge(account, d, metadata)
  end

  @spec get(String.t(), atom(), Chat.t(), Account.t()) ::
          Definition.t() | nil
  def get(var, :text = kind, chat, account) do
    metadata = %{kind: kind, var: var}
    search(metadata, chat, account)
  end

  # TODO: Rename this to find_one, make another generic find() that returns
  #   entire list with ability to specify query scope.
  @spec search(Map.t(), Chat.t(), Account.t()) :: Definition.t() | nil
  defp search(metadata, chat, account, depth \\ 1, res \\ [])
  defp search(_, _, _, _, [d | _]), do: d

  defp search(metadata, chat, account, 1, []) do
    Logger.info("search() depth=1")
    ## search in this chat or by this account
    # in this chat
    {:ok, res_c} = DB.Graph.adjacent(chat, @defn_label, metadata)
    # by this account
    {:ok, res_a} = DB.Graph.adjacent(account, @defn_label, metadata)

    search(metadata, chat, account, 2, (res_c ++ res_a) |> sort_results())
  end

  defp search(metadata, chat, account, 2, []) do
    Logger.info("search() depth=2")
    ## search in any chat we've been in
    {:ok, res} =
      DB.Graph.path(account, [
        PlatformAccount,
        Chat,
        Definition
      ])

    search(metadata, chat, account, 3, res |> sort_results())
  end

  defp search(metadata, chat, account, 3, []) do
    Logger.info("search() depth=3")
    ## search all of our friends' definitions
    {:ok, res} =
      DB.Graph.path(account, [
        PlatformAccount,
        Chat,
        PlatformAccount,
        Account,
        Definition
      ])

    search(metadata, chat, account, 0, res |> sort_results())
  end

  defp search(_, _, _, 0, _), do: nil

  @spec sort_results([Definition.t()]) :: [Definition.t()]
  defp sort_results([]), do: []
  defp sort_results(ds), do: ds |> DB.get_all() |> Enum.sort_by(fn d -> d.date end, :desc)
end
