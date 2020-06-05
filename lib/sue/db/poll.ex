defmodule Sue.DB.Poll do
  alias Sue.DB
  alias Sue.Models.{Chat, Account}

  def db_tables() do
    [
      {
        :polls,
        [
          type: :set,
          attributes: [:key, :val]
        ]
      }
    ]
  end

  @spec set(Chat.t(), Map.t()) :: any()
  def set(chat, poll), do: DB.set({:polls, chat, poll})

  @spec get(any) :: {:error, any} | {:ok, any}
  def get(chat), do: DB.get(:polls, chat)

  @doc """
  Create a new poll for a chat.
  """
  @spec new(Chat.t(), String.t(), [String.t()]) :: Map.t()
  def new(chat, topic, choices) do
    poll = %{topic: topic, choices: choices, votes: %{}}
    set(chat, poll)
    poll
  end

  @doc """
  Marks a chat as having an active "custom" poll, where the poll is handled by
    the application rather than Sue.
  """
  @spec new_custom(Chat.t(), String.t(), [String.t()]) :: Map.t()
  def new_custom(chat, topic, choices) do
    set(chat, :custom)
    %{topic: topic, choices: choices, votes: %{}}
  end

  @spec update(Chat.t(), Account.t(), integer()) ::
          {:ok, Map.t()} | {:error, String.t()}
  def update(chat, account, choiceIdx) do
    with {:ok, poll} <- get(chat) do
      %{topic: topic, choices: choices, votes: votes} = poll

      cond do
        choiceIdx < 0 ->
          {:error, "Not an option in this poll. See: !help vote"}

        choiceIdx >= length(choices) ->
          {:error, "Not an option in this poll. See: !help vote"}

        true ->
          newpoll = %{
            topic: topic,
            choices: choices,
            votes: Map.put(votes, account.id, choiceIdx)
          }

          {:ok, _} = set(chat, newpoll)
          {:ok, newpoll}
      end
    else
      {:error, _} -> {:error, "Chat has no active poll. Create one with !poll"}
    end
  end
end
