defmodule Subaru.Subgraph do
  defstruct [:vs, :es]

  @type t() :: %__MODULE__{
          vs: [Subaru.Vertex.t()],
          es: [Subaru.Edge.t()]
        }
end
