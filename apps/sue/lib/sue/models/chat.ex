defmodule Sue.Models.Chat do
  @enforce_keys [:platform, :id, :is_direct]
  defstruct [:platform, :id, :is_direct]

  @type t() :: %__MODULE__{
          platform: Sue.Models.Platform.t(),
          id: integer() | String.t(),
          # is a 1:1 convo with Sue
          is_direct: boolean()
        }
end
