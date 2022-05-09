defmodule Sue.New.Defn do
  @behaviour Subaru.Vertex

  defstruct [:var, :val, :type, :date_created, :date_modified, :id]

  @type t() :: %__MODULE__{
          var: String.t(),
          val: String.t() | integer(),
          type: :text | :num | :bin | :func,
          date_created: integer(),
          date_modified: integer(),
          id: any()
        }

  @collection "sue_defns"

  alias __MODULE__

  # TODO: Add support for more defn types (currently just :text)
  @spec new(bitstring(), bitstring(), atom()) :: Defn.t()
  def new(var, val, :text = type) do
    now = Sue.Utils.unix_now()

    %Defn{
      var: var,
      val: val,
      type: type,
      date_created: now,
      date_modified: now
    }
  end

  @impl Subaru.Vertex
  def collection(), do: @collection

  @impl Subaru.Vertex
  def doc(d), do: Sue.Utils.struct_to_map(d)
end
