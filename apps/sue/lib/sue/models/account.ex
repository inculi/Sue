defmodule Sue.Models.Account do
  @enforce_keys [:ref]
  defstruct [:ref, name: "Anonymous"]

  @type t() :: %__MODULE__{
          ref: reference(),
          name: String.t()
        }

  alias Sue.DB
  alias Sue.Models.PlatformAccount

  @doc """
  Find Account, otherwise create it.
  """
  @spec resolve(PlatformAccount.t()) :: Account.t()
  def resolve(platform_account) do
    potentially_new_account = %Sue.Models.Account{
      ref: make_ref()
    }

    {:ok, account} = DB.Graph.getsert_bi_edge_if_unique(platform_account, potentially_new_account)
    account
  end
end
