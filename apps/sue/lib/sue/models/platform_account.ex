defmodule Sue.Models.PlatformAccount do
  @moduledoc """
  Provide a basis for mapping a phone number / messenger account to a
    Sue account. As we primarily *act* on Sue.Models.Account objects, the only
    edge that we should draw to/from these vertices are to the Sue %Account{}s.
  """

  @behaviour Subaru.Vertex

  @enforce_keys [:platform_id]
  defstruct [:platform_id, :id]

  @collection "sue_platformaccounts"

  alias __MODULE__
  alias Sue.Models.Platform

  @type t() :: %__MODULE__{
          platform_id: {Platform.t(), bitstring() | integer()},
          id: nil | bitstring()
        }

  def resolve(pa) do
    {platform, id} = pa.platform_id
    doc_search = %{platform: platform, id: id}
    doc_insert = doc(pa)

    {:ok, subaru_id} = Subaru.upsert(doc_search, doc_insert, %{}, @collection)
    %PlatformAccount{pa | id: subaru_id}
  end

  @impl Subaru.Vertex
  def collection(), do: @collection

  @impl Subaru.Vertex
  def doc(%PlatformAccount{platform_id: {platform, id}}) do
    %{platform: platform, id: id}
  end
end
