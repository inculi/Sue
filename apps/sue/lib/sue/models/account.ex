defmodule Sue.Models.Account do
  @behaviour Subaru.Vertex

  defstruct [:id, name: "", handle: ""]

  @collection "sue_users"

  @type t() :: %__MODULE__{
          name: bitstring(),
          handle: bitstring(),
          id: nil | bitstring()
        }

  alias Sue.Models.PlatformAccount
  alias __MODULE__

  @spec from_paccount(PlatformAccount.t()) :: t()
  @doc """
  Resolves a Sue Account from its associated PlatformAccount.
  An edge should ideally exist between the two in the database.
  If not, the account is created. As the PAccount cannot be nil, it is assumed
    the PAccount is already resolved to a Subaru.dbid
  """
  def from_paccount(pa) do
    account_id = Sue.DB.link_paccount_to_resolved_user(pa)

    Subaru.get!(@collection, account_id)
    |> from_doc()
  end

  @spec from_doc(Map.t()) :: t
  def from_doc(doc) do
    %Account{
      name: doc.name,
      handle: doc.handle,
      id: doc._id
    }
  end

  @impl Subaru.Vertex
  def collection(), do: @collection

  @impl Subaru.Vertex
  def doc(a) do
    %{name: a.name, handle: a.handle, id: a.id}
  end
end
