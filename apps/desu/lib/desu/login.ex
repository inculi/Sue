defmodule Desu.Login do
  use GenServer

  @cache_table :desu_login_cache

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
  @spec gen_code(any()) :: {:ok, integer()}
  def gen_code(stored_secret) do
    code = 100_000 + :rand.uniform(899_999)
    {:ok, _} = Subaru.Cache.put_ttl(@cache_table, code, stored_secret, :timer.minutes(5))
    {:ok, code}
  end

  @doc """
  See list of active codes.
  """
  def active_codes() do
    Subaru.Cache.keys(@cache_table)
  end

  defp remove_code(pin) do
    Subaru.Cache.del(@cache_table, pin)
  end
end
