defmodule Sue.New.Chat do
  @enforce_keys [:platform_id, :is_direct]
  defstruct [:platform_id, :is_direct, :id]

  @behaviour Subaru.Vertex

  @type t() :: %__MODULE__{
          platform_id: {bitstring(), bitstring() | integer()},
          # is a 1:1 convo with Sue
          is_direct: boolean(),
          id: nil | bitstring()
        }

  @collection "sue_chats"

  alias __MODULE__

  @spec resolve(t) :: t
  def resolve(c) do
    {platform, id} = c.platform_id
    doc_search = %{platform: platform, id: id}
    doc_insert = doc(c)

    {:ok, chat_id} = Subaru.upsert(doc_search, doc_insert, %{}, @collection)
    struct(c, id: chat_id)
    # %Chat{c | id: chat_id}
  end

  def from_doc(d) do
    %Chat{
      platform_id: {d.platform, d.id},
      is_direct: d.is_direct,
      id: d._id
    }
  end

  @impl Subaru.Vertex
  def collection(), do: @collection

  @impl Subaru.Vertex
  def doc(%Chat{platform_id: {platform, id}} = c) do
    %{platform: platform, is_direct: c.is_direct, id: id}
  end
end
