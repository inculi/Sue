defmodule Sue.Models.Account do
  @moduledoc """
  Represents and connects the cross-platform engagements of an individual.
  """

  alias __MODULE__
  alias Sue.Models.{Message, Buddy}
  alias Sue.DB

  @type t() :: %__MODULE__{}
  @enforce_keys [:id]
  defstruct [:id]

  @spec resolve_and_relate(Sue.Models.Message.t()) :: Account.t()
  def resolve_and_relate(%Message{} = msg) do
    account = resolve(msg)
    DB.Graph.add_biedge("account", "chat", account.id, msg.chat)
    account
  end

  defp resolve(%Message{platform: platform, buddy: %Buddy{id: id}}) do
    %Account{id: Sue.DB.Account.obtain_id(platform, id)}
  end
end
