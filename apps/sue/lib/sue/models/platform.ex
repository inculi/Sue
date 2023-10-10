defmodule Sue.Models.Platform do
  @moduledoc """
  These are the currently supported messaging platforms. If you want to Sue to
    support a new platform, it should also be defined here.

  :debug is only used in testing
  """
  @type t() :: :imessage | :telegram | :discord | :debug
end
