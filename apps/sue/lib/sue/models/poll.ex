defmodule Sue.Models.Poll do
  @enforce_keys [:chat, :topic, :options, :votes, :interface]
  defstruct [:chat, :topic, :options, :votes, interface: :standard]

  @type interface() :: :standard | :platform
  @type t() :: %__MODULE__{
          chat: Sue.Models.Chat.t(),
          topic: String.t(),
          options: [String.t()],
          # k:PlatformAccount, v:ChoiceIndex
          votes: Map.t(),
          interface: interface()
        }

  alias __MODULE__
  alias Sue.DB
  alias Sue.DB.Schema.Vertex

  @doc """
  Add new poll to db.
  """
  @spec new(Chat.t(), String.t(), [String.t()], interface()) :: Poll.t()
  def new(chat, topic, options, interface) do
    newpoll = %Poll{
      chat: chat,
      topic: topic,
      options: options,
      votes: %{},
      interface: interface
    }

    {:ok, :ok} = DB.Graph.add_vertex(newpoll)

    newpoll
  end

  @doc """
  Retrieve poll from db.
  """
  def get(chat), do: DB.get(Vertex.label(Poll), chat)

  @doc """
  Update poll with new voter.
  """
  @spec add_vote(Chat.t(), PlatformAccount.t(), integer()) :: DB.result()
  def add_vote(chat, platform_account, choice_idx) do
    fn ->
      with {:ok, poll} <- DB.t_get(DB.Schema.Vertex.label(__MODULE__), chat).() do
        new_poll = %Poll{poll | votes: Map.put(poll.votes, platform_account, choice_idx)}
        DB.Graph.t_add_vertex(new_poll).()
        {:ok, new_poll}
      else
        _ -> {:error, :dne}
      end
    end
    |> DB.exec()
  end
end
