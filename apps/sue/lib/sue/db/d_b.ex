defmodule Sue.DB do
  @moduledoc """
  The following is, I suppose, temporary. While I find Mnesia really cool, I
    think going forward we're better off using something else.
  """

  use GenServer

  require Logger

  alias __MODULE__
  alias :mnesia, as: Mnesia
  alias DB.Schema

  @type result() :: {:ok, any()} | {:error, any()}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    db_nodes = [Node.self() | Node.list()]

    Mnesia.create_schema(db_nodes)
    :ok = Mnesia.start()
    :ok = Mnesia.wait_for_tables(Mnesia.system_info(:local_tables), 5_000)

    init_schema(db_nodes)

    {:ok, []}
  end

  # Public API
  @spec set(atom(), any(), any()) :: any()
  def set(table, key, val) do
    with {:ok, res} <- write({table, key, val}) do
      res
    end
  end

  @spec get(Schema.Vertex.t()) :: {:ok, any()} | {:error, :dne}
  def get(v), do: get(Schema.Vertex.label(v), Schema.Vertex.id(v))

  @spec get(atom(), any()) :: {:ok, any()} | {:error, :dne}
  def get(table, key), do: t_get(table, key) |> exec()

  @spec get!(atom(), any()) :: any()
  def get!(table, key) do
    with {:ok, val} <- get(table, key) do
      val
    else
      {:error, :dne} -> nil
    end
  end

  def get!(v), do: get!(Schema.Vertex.label(v), Schema.Vertex.id(v))

  @spec t_get(Schema.Vertex.t()) :: fun()
  def t_get(v), do: t_get(Schema.Vertex.label(v), Schema.Vertex.id(v))

  @spec t_get(atom(), any()) :: fun()
  def t_get(table, key) do
    fn ->
      case Mnesia.read(table, key) do
        [] -> {:error, :dne}
        [{^table, ^key, val}] -> {:ok, val}
      end
    end
  end

  # TODO: optimize
  @spec get_all([{atom(), any()}]) :: [any()]
  def get_all(tups) do
    for {table, id} <- tups do
      get!(table, id)
    end
  end

  # Mnesia wrappers, best not use these outside of Sue.DB.*
  @spec write(tuple()) :: result()
  def write(record), do: t_write(record) |> exec()

  @spec t_write(tuple()) :: fun()
  def t_write(record), do: fn -> Mnesia.write(record) end

  @spec read(tuple()) :: result()
  def read(record), do: t_read(record) |> exec()

  @spec t_read(tuple()) :: fun()
  def t_read(record), do: fn -> Mnesia.read(record) end

  def match(record), do: t_match(record) |> DB.exec()

  def match!(record) do
    {:ok, res} = match(record)
    res
  end

  @spec t_match(tuple()) :: fun()
  def t_match(record), do: fn -> Mnesia.match_object(record) end

  # Internal Methods :: Setup
  def init_schema(db_nodes) do
    for {table_name, table_opts} <- Schema.tables() do
      create_table(table_name, Keyword.put(table_opts, :disc_copies, db_nodes))
    end
  end

  # Internal Methods :: Utility
  @spec exec(fun()) :: result()
  def exec(f), do: f |> Mnesia.transaction() |> elixirize_output()

  @spec elixirize_output({:aborted, any} | {:atomic, any}) :: result()
  def elixirize_output(out) do
    case out do
      # avoid {:ok, {:error, _}}
      {:atomic, {:error, _reason} = err_reason} -> err_reason
      # avoid {:ok, {:ok, _}}
      {:atomic, {:ok, _result} = ok_result} -> ok_result
      # likely {:ok, :ok}
      {:atomic, val} -> {:ok, val}
      # mnesia error
      {:aborted, reason} -> {:error, reason}
    end
  end

  defp create_table(name, opts) when is_atom(name) do
    res = Mnesia.create_table(name, opts)
    # Logger.info("create_table(#{name}) -> #{inspect(res)}")
    res
  end
end
