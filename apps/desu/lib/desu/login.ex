defmodule Desu.Login do
  use GenServer

  @cache_table :desu_login_cache
  @chars String.graphemes("ABCDEFGHJKLMNOPQRSTUVWXYZ0123456789")

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok, %{}}
  end

  @doc """
  Generate a login code that a user can send to Sue to authenticate. Expires
  after 5 minutes.
  """
  @spec gen_code(any()) :: bitstring()
  def gen_code(stored_secret) do
    # Generate code
    newcode = for(_n <- 1..6, do: Enum.random(@chars)) |> Enum.join()

    # Make sure we don't have multiple codes pointing to the same stored_secret
    code =
      case Subaru.Cache.get(@cache_table, stored_secret) do
        # DNE, safe to make new code
        {:ok, nil} ->
          {:ok, _} = Subaru.Cache.put_ttl(@cache_table, newcode, stored_secret, :timer.minutes(5))
          {:ok, _} = Subaru.Cache.put_ttl(@cache_table, stored_secret, newcode, :timer.minutes(5))
          newcode

        # Exists, refresh and return last code
        {:ok, oldcode} ->
          Subaru.Cache.refresh(@cache_table, stored_secret)
          Subaru.Cache.refresh(@cache_table, oldcode)
          oldcode
      end

    code
  end

  @doc """
  See list of active codes.
  """
  def active_codes() do
    Subaru.Cache.keys(@cache_table)
  end

  @doc """
  Try using code. Expire if successful.
  """
  @spec try_and_expire_code(bitstring()) :: {:ok, true} | {:ok, false}
  def try_and_expire_code(code) do
    case Subaru.Cache.get(@cache_table, code) do
      {:ok, nil} ->
        {:ok, false}

      {:ok, stored_secret} ->
        Subaru.Cache.del(@cache_table, code)
        Subaru.Cache.del(@cache_table, stored_secret)
        {:ok, true}
    end
  end
end
