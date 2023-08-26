defmodule Sue.Models.PlatformAccount do
  @moduledoc """
  """

  defstruct [:id, :platform, :platform_id]

  @type t() :: %__MODULE__{
          id: nil | bitstring(),
          platform: Sue.Models.Platform.t(),
          platform_id: bitstring() | integer()
        }
end
