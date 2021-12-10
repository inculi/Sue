defmodule Sue.New.Account do
  defstruct [:name, :handle, :id]

  @collection "sue_users"

  @type t() :: %__MODULE__{
          name: bitstring(),
          handle: bitstring(),
          id: any()
        }

  alias __MODULE__

  def resolve(%Account{id: nil, name: name, handle: handle})
      when is_bitstring(name) and is_bitstring(handle) do
    expr =
      {:and, {:==, "x.name", Sue.Utils.quoted(name)}, {:==, "x.handle", Sue.Utils.quoted(handle)}}

    Sue.New.DB.find_one(@collection, expr)
  end

  defimpl Subaru.Vertex, for: __MODULE__ do
    def collection(_a), do: "sue_users"

    def doc(a), do: %{name: a.name, handle: a.handle}
  end
end
