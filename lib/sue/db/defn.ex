defmodule Sue.DB.Defn do
  alias :mnesia, as: Mnesia
  alias Sue.DB
  alias Sue.Models.{Account, Chat}

  def db_tables() do
    [
      {
        :defns,
        [
          type: :bag,
          attributes: [:var, :val, :account, :chat, :date],
          index: [:account, :chat]
        ]
      }
    ]
  end

  @spec set(String.t(), String.t(), Account.t(), Chat.t()) :: {:error, any} | {:ok, any}
  def set(var, val, account, chat) do
    date = DateTime.utc_now() |> DateTime.to_unix()
    DB.write({:defns, var, val, account.id, chat, date})
  end

  @spec get(String.t(), Account.t(), Chat.t()) :: {:ok, any} | {:error, :not_found}
  def get(var, account, chat), do: resolve_defn(var, account, chat, 1)

  # The first stage of resolving the definition looks for definitions made by
  #   you, or in the current chat (by anyone).
  @spec resolve_defn(String.t(), Account.t(), Chat.t(), 1 | 2) ::
          {:ok, String.t()} | {:error, :not_found}
  defp resolve_defn(var, account, chat, 1) do
    case find_local_var_records(var, account.id, chat.id) do
      {:ok, []} ->
        resolve_defn(var, account, chat, 2)

      {:error, _} ->
        resolve_defn(var, account, chat, 2)

      {:ok, records} ->
        records
        |> sort_records_by_date()
        |> hd()
        |> (fn {_, _, meaning, _, _, _} -> {:ok, meaning} end).()
    end
  end

  # The second stage of resolution first gets all definitions for the word, then checks:
  #   1. If any of your chats have defined that word.
  #   2. If any of your friends hvae defined that word in *their* chats.
  defp resolve_defn(var, account, _chat, 2) do
    {:ok, all_var_records} = find_all_var_records(var)
    account_chats = DB.Graph.get_account_chat(account)
    account_friends = DB.Graph.get_multi_chat_account(account_chats)

    all_var_records =
      all_var_records
      |> sort_records_by_date()

    chat_hits =
      MapSet.intersection(
        account_chats
        |> MapSet.new(),
        all_var_records
        |> extract_record_chat()
        |> MapSet.new()
      )
      |> MapSet.to_list()

    account_hits =
      MapSet.intersection(
        account_friends
        |> MapSet.new(),
        all_var_records
        |> extract_record_account()
        |> MapSet.new()
      )
      |> MapSet.to_list()

    cond do
      chat_hits != [] ->
        hit = chat_hits |> hd()

        {:ok,
         Enum.find(all_var_records, fn {_, _, _, _, h, _} -> h == hit end)
         |> (fn {_, _, meaning, _, _, _} -> meaning end).()}

      account_hits != [] ->
        hit = account_hits |> hd()

        {:ok,
         Enum.find(all_var_records, fn {_, _, _, h, _, _} -> h == hit end)
         |> (fn {_, _, meaning, _, _, _} -> meaning end).()}

      true ->
        {:error, :not_found}
    end
  end

  @spec extract_record_chat([tuple()]) :: [Chat.t()]
  defp extract_record_chat(records) do
    records
    |> Enum.map(fn {_, _, _, _, chat, _} -> chat end)
  end

  @spec extract_record_account([tuple()]) :: [Account.t()]
  defp extract_record_account(records) do
    records
    |> Enum.map(fn {_, _, _, account_id, _, _} -> %Account{id: account_id} end)
  end

  @spec sort_records_by_date([tuple()]) :: [tuple()]
  defp sort_records_by_date(records) do
    records
    |> Enum.sort_by(fn {_, _, _, _, _, d} -> d end, :desc)
  end

  # Find definitions made by the acquiring account, or made in the present chat.
  @spec find_local_var_records(String.t(), Account.t(), Chat.t()) ::
          {:error, any} | {:ok, [tuple()]}
  defp find_local_var_records(var, account, chat) do
    fn ->
      Mnesia.select(
        :defns,
        [
          {
            # select all fields in record
            {:defns, :"$1", :"$2", :"$3", :"$4", :"$5"},
            [
              {
                :and,
                # has to be definition we called AND
                {:==, :"$1", var},
                # has to either
                {
                  :orelse,
                  # be made by us OR
                  {:==, :"$3", account},
                  # be made in the chat we are using
                  {:==, :"$4", chat}
                }
              }
            ],
            # return everything we selected
            [:"$$"]
          }
        ]
      )
    end
    |> Mnesia.transaction()
    |> case do
      {:atomic, []} ->
        {:ok, []}

      {:atomic, [h | _] = res} when is_list(h) ->
        {:ok,
         for x <- res do
           List.to_tuple([:defns | x])
         end}

      {:aborted, reason} ->
        {:error, reason}
    end
  end

  # Find all definitions equal to a certain word, they will be filtered
  #   accordingly soon.
  @spec find_all_var_records(String.t()) :: {:ok, [tuple()]} | {:error, any()}
  defp find_all_var_records(var) do
    DB.match({:defns, var, :_, :_, :_, :_})
  end
end
