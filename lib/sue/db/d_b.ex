defmodule Sue.DB do
  @moduledoc """
  The following is, I suppose, temporary. While I find Mnesia really cool, I
    think going forward we're better off using something else.
  """

  use GenServer

  require Logger

  alias __MODULE__
  alias :mnesia, as: Mnesia

  @kv_tables [:state]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    nodes = [Node.self() | Node.list()]

    Mnesia.create_schema(nodes)
    :ok = Mnesia.start()
    :ok = Mnesia.wait_for_tables(Mnesia.system_info(:local_tables), 5_000)

    create_tables(nodes)

    {:ok, []}
  end

  def set({table, k, v}) when is_atom(table), do: write({table, k, v})

  def write(record) when is_tuple(record) do
    fn -> Mnesia.write(record) end
    |> Mnesia.transaction()
    |> elixirize_output()
  end

  @spec get!(Atom.t(), any, any) :: any
  def get!(table, key, default \\ nil) do
    {:ok, val} = get(table, key, default)
    val
  end

  @spec get(Atom.t(), any, any) :: {:error, any} | {:ok, any}
  def get(table, key, default \\ nil) do
    with {:atomic, res} <-
           fn -> Mnesia.read({table, key}) end
           |> Mnesia.transaction() do
      case res do
        [] -> {:ok, default}
        [{^table, ^key, val}] -> {:ok, val}
      end
    else
      {:aborted, reason} -> {:error, reason}
    end
  end

  def create_table(name, opts) when is_atom(name) do
    Mnesia.create_table(name, opts)
  end

  def clear_table(name) when is_atom(name) do
    Mnesia.clear_table(name)
  end

  def all_keys(name) when is_atom(name) do
    fn -> Mnesia.all_keys(name) end
    |> Mnesia.transaction()
  end

  defp create_tables(nodes) do
    # Generic KVs
    for kv_table_name <- @kv_tables do
      create_table(kv_table_name,
        type: :set,
        disc_copies: nodes,
        attributes: [:key, :val]
      )
    end

    # Individual Modules
    [DB.Account, DB.Defn, DB.Graph, DB.Poll]
    |> Enum.map(fn module ->
      module.db_tables()
      |> Enum.map(fn {table_name, opts} ->
        res = create_table(table_name, opts |> Keyword.put_new(:disc_copies, nodes))
        Logger.info("[Sue.DB] create_table(#{table_name}) -> #{inspect(res)}")
      end)
    end)
  end

  def match!(record) when is_tuple(record) do
    {:ok, res} = match(record)
    res
  end

  @spec match!(tuple) :: [tuple()]
  def match!(record) do
    {:ok, res} = match(record)
    res
  end

  @spec match(tuple) :: {:error, any} | {:ok, [tuple()]}
  def match(record) when is_tuple(record) do
    fn -> Mnesia.match_object(record) end
    |> Mnesia.transaction()
    |> elixirize_output()
  end

  def elixirize_output(out) do
    case out do
      {:atomic, res} -> {:ok, res}
      {:aborted, reason} -> {:error, reason}
    end
  end
end
