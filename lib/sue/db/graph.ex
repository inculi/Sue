defmodule Sue.DB.Graph do
  alias Sue.DB
  alias Sue.Models.{Account, Chat}

  require Logger

  def db_tables() do
    [
      {
        :graph,
        [
          type: :set,
          attributes: [:key, :val]
        ]
      }
    ]
  end

  def add_edge(edge_type, src, dst) when is_atom(edge_type) do
    DB.write({:graph, {edge_type, src, dst}, 1})
  end

  @spec add_biedge(Atom.t() | String.t(), Atom.t() | String.t(), any, any) ::
          {:error, any} | {:ok, any}
  def add_biedge(src_type, dst_type, src, dst) do
    add_edge(:"#{src_type}_#{dst_type}", src, dst)
    add_edge(:"#{dst_type}_#{src_type}", dst, src)
  end

  @spec get_account_chat(Account.t()) :: [Chat.t()]
  def get_account_chat(%Account{id: id}) when is_reference(id) do
    DB.match!({:graph, {:account_chat, id, :_}, :_})
    |> Enum.map(fn {_, {_, _, chat}, _} ->
      chat
    end)
  end

  @spec get_chat_account(Chat.t()) :: [Account.t()]
  def get_chat_account(chat) do
    DB.match!({:graph, {:chat_account, :_, chat}, :_})
    |> Enum.map(fn {_, {_, aid, _}, _} ->
      %Account{id: aid}
    end)
  end

  @spec get_multi_chat_account([Chat.t()]) :: [Account.t()]
  def get_multi_chat_account(chats) do
    chats
    |> Enum.reduce(MapSet.new(), fn chat, acc ->
      chat
      |> get_chat_account()
      |> MapSet.new()
      |> MapSet.union(acc)
    end)
    |> MapSet.to_list()
  end

  @doc """
  For a specified account A, return other accounts they have into contact with,
    by means of the chats they are a part of.
  """
  @spec get_account_chat_account(Account.t()) :: [Account.t()]
  def get_account_chat_account(a) do
    a
    |> get_account_chat()
    |> get_multi_chat_account()
  end
end
