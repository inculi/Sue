defmodule Sue.Models.PlatformAccount do
  @enforce_keys [:platform, :id]
  defstruct [:platform, :id]

  @type t() :: %__MODULE__{
          platform: Sue.Models.Platform.t(),
          id: integer() | String.t()
        }
end
