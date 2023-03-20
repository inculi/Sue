defmodule Subaru.Edge do
  @moduledoc """
  For future use. See Subaru.Query moduledoc.
  """
  alias __MODULE__

  defstruct [:collection, :fromid, :toid]

  @type t() :: %__MODULE__{
          collection: bitstring(),
          fromid: Subaru.dbid(),
          toid: Subaru.dbid()
        }

  @spec new(bitstring(), Subaru.dbid(), Subaru.dbid()) :: t
  def new(collection, fromid, toid) do
    %Edge{
      collection: collection,
      fromid: fromid,
      toid: toid
    }
  end
end
