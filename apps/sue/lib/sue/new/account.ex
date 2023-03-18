defmodule Sue.New.Account do
  @behaviour Subaru.Vertex

  @enforce_keys [:platform_id]
  defstruct [:name, :handle, :platform_id, :id]

  @collection "sue_users"

  @type t() :: %__MODULE__{
          name: bitstring(),
          handle: bitstring(),
          platform_id: {atom(), integer() | bitstring()},
          id: nil | bitstring()
        }

  alias __MODULE__

  @spec resolve(t) :: t
  def resolve(a) do
    {platform, id} = a.platform_id
    doc_search = %{platform: platform, id: id}
    doc_insert = doc(a)

    {:ok, account_id} = Subaru.upsert(doc_search, doc_insert, %{}, @collection)
    %Account{a | id: account_id}
  end

  @spec from_doc(Map.t()) :: t
  def from_doc(doc) do
    %Account{
      name: doc.name,
      handle: doc.handle,
      platform_id: {string_to_atom(doc.platform), doc.id},
      id: doc._id
    }
  end

  @spec string_to_atom(atom | bitstring()) :: atom
  def string_to_atom(s) when is_bitstring(s), do: String.to_atom(s)
  def string_to_atom(a) when is_atom(a), do: a

  @impl Subaru.Vertex
  def collection(), do: @collection

  @impl Subaru.Vertex
  def doc(%Account{platform_id: {platform, id}} = a) do
    %{name: a.name, handle: a.handle, platform: platform, id: id}
  end
end
