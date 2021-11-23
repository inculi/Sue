defmodule Sue.New.Defn do
  defstruct [:var, :val, :type, :date_created, :date_modified, :id]

  @type t() :: %__MODULE__{
          var: String.t(),
          val: String.t() | integer(),
          type: :text | :num | :bin | :func,
          date_created: integer(),
          date_modified: integer(),
          id: any()
        }

  alias __MODULE__

  # only support text for time being
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
end
