defmodule Sue.Models.Chat do
  @type t() :: %__MODULE__{}
  @enforce_keys [:platform, :id, :is_direct]
  defstruct [:platform, :id, :is_direct]
end
