defmodule Sue.New.Account do
  defstruct [:name, :handle, :platform_id, :id]

  @collection "sue_users"

  @type t() :: %__MODULE__{
          name: bitstring(),
          handle: bitstring(),
          platform_id: {bitstring(), integer() | any()},
          id: nil | bitstring()
        }

  alias __MODULE__

  @spec resolve(t) :: t
  def resolve(a) do
    {platform, id} = a.platform_id
    doc_search = %{platform: platform, id: id}
    doc_insert = Subaru.Vertex.doc(a)

    account_id = Subaru.upsert(doc_search, doc_insert, %{}, @collection)

    %Account{a | id: account_id}
  end

  @spec from_doc(Map.t()) :: t
  def from_doc(doc) do
    %Account{
      name: doc.name,
      handle: doc.handle,
      platform_id: {doc.platform, doc.id},
      id: doc._id
    }
  end

  defimpl Subaru.Vertex, for: __MODULE__ do
    def collection(_a), do: "sue_users"

    def doc(%Account{platform_id: {platform, id}} = a) do
      %{name: a.name, handle: a.handle, platform: platform, id: id}
    end
  end
end
