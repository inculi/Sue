defmodule Subaru.DB do
  use GenServer

  require Logger

  @type res() :: {:ok, [Arangox.Response.t()] | :dne} | {:error, any()}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init([database_name]) when is_bitstring(database_name) do
    options = [
      username: Application.fetch_env!(:arangox, :username),
      password: Application.fetch_env!(:arangox, :password),
      endpoints: Application.fetch_env!(:arangox, :endpoints),
      database: database_name
    ]

    {:ok, conn} = Arangox.start_link(options)
    {:ok, conn, {:continue, :post_init}}
  end

  @impl true
  def handle_continue(:post_init, conn) do
    {:noreply, conn}
  end

  @impl true
  def handle_call(:ping, _from, conn) do
    {:reply, :pong, conn}
  end

  @impl true
  def handle_call({:insert, doc, collection}, _from, conn) do
    bindvars = %{
      "doc" => doc,
      "@col" => collection
    }

    {:ok, response} =
      exec(conn, "INSERT @doc INTO @@col RETURN NEW._id", bindvars, write: collection)

    {:reply, response, conn}
  end

  @impl true
  def handle_call({:insert_edge, fromid, toid, edge_collection}, _from, conn) do
    bindvars = %{
      "fromid" => fromid,
      "toid" => toid,
      "@col" => edge_collection
    }

    {:ok, response} =
      exec(conn, "INSERT {_from: @fromid, _to: @toid} INTO @@col", bindvars,
        write: edge_collection
      )

    {:reply, response, conn}
  end

  @impl true
  def handle_call({:insert_multi, items_and_collections}, _from, conn) do
    {statements, bindvars} =
      items_and_collections
      |> Enum.with_index()
      |> Enum.map(&add_multi_helper/1)
      |> Enum.unzip()

    statement = Enum.join(statements, "\n")
    bindvars = Enum.reduce(bindvars, fn x, acc -> Map.merge(acc, x) end)

    writecolls =
      bindvars
      |> Map.keys()
      |> Enum.filter(fn k -> String.starts_with?(k, "@coll") end)
      |> Enum.map(fn k -> bindvars[k] end)

    {:ok, response} = exec(conn, statement, bindvars, write: writecolls)

    {:reply, response, conn}
  end

  @impl true
  def handle_call({:upsert, searchdoc, insertdoc, updatedoc, collection}, _from, conn) do
    bindvars = %{
      "sdoc" => searchdoc,
      "idoc" => insertdoc,
      "udoc" => updatedoc,
      "@col" => collection
    }

    {:ok, response} =
      exec(conn, "UPSERT @sdoc INSERT @idoc UPDATE @udoc IN @@col RETURN NEW._id", bindvars,
        write: collection
      )

    {:reply, response, conn}
  end

  @impl true
  def handle_call({:list, coll}, _from, conn) do
    {:ok, [res]} = exec(conn, "FOR x in @@col RETURN x", %{"@col" => coll}, read: coll)
    {:reply, res.body["result"], conn}
  end

  @impl true
  def handle_call(:conn, _from, conn) do
    {:reply, conn, conn}
  end

  @impl true
  def handle_call({:create_collection, name, type}, _from, conn) do
    res = create_collection(conn, name, type)
    {:reply, res, conn}
  end

  def handle_call({:remove_collection, name}, _from, conn) do
    out = remove_collection(conn, name)
    {:reply, out, conn}
  end

  @impl true
  def handle_call({:exec, statement, bindvars, opts}, _from, conn) do
    res = exec(conn, statement, bindvars, opts)
    {:reply, res, conn}
  end

  # PUBLIC API
  # ==========

  @spec exec(bitstring(), map(), keyword()) :: res()
  def exec(statement, bindvars, opts) do
    GenServer.call(__MODULE__, {:exec, statement, bindvars, opts})
  end

  def ping() do
    GenServer.call(__MODULE__, :ping)
  end

  @spec insert(Map.t(), bitstring()) :: any
  def insert(doc, collection) do
    GenServer.call(__MODULE__, {:insert, doc, collection})
  end

  @spec upsert(Map.t(), Map.t(), Map.t(), bitstring()) :: any
  def upsert(searchdoc, insertdoc, updatedoc, collection) do
    GenServer.call(__MODULE__, {:upsert, searchdoc, insertdoc, updatedoc, collection})
  end

  def insert_edge(fromid, toid, collection) do
    GenServer.call(__MODULE__, {:insert_edge, fromid, toid, collection})
  end

  @spec list(bitstring()) :: any
  def list(collection) do
    GenServer.call(__MODULE__, {:list, collection})
  end

  @spec conn :: pid()
  def conn() do
    GenServer.call(__MODULE__, :conn)
  end

  @spec create_collection(bitstring(), :doc | :edge) :: {:ok, bitstring()}
  def create_collection(name, type) do
    GenServer.call(__MODULE__, {:create_collection, name, type})
  end

  @spec remove_collection(bitstring()) :: {:ok, bitstring()} | {:error, :dne}
  def remove_collection(name) do
    GenServer.call(__MODULE__, {:remove_collection, name})
  end

  @spec add_multi([{:doc | :edge, Map.t(), bitstring()}, ...]) :: any()
  def add_multi([]), do: {[], %{}}

  def add_multi(items_and_collections) do
    GenServer.call(__MODULE__, {:insert_multi, items_and_collections})
  end

  def debug_exec(query, bindvars, opts) do
    exec(conn(), query, bindvars, opts)
  end

  # HELPER METHODS
  # ==============

  defp add_multi_helper({{:doc, doc, coll}, idx}) do
    dockey = "doc#{idx}"
    collkey = "@coll#{idx}"
    bindvars = %{dockey => doc, collkey => coll}
    {"INSERT @#{dockey} INTO @#{collkey}", bindvars}
  end

  defp add_multi_helper({{:edge, %{_from: fromid, _to: toid}, coll}, idx}) do
    fromkey = "fromid#{idx}"
    tokey = "toid#{idx}"
    collkey = "@coll#{idx}"
    bindvars = %{fromkey => fromid, tokey => toid, collkey => coll}

    {"INSERT {_from: @#{fromkey}, _to: @#{tokey}} INTO @#{collkey}", bindvars}
  end

  # HELPER UTILS
  # ============

  @spec exec(pid(), bitstring(), map(), keyword()) :: res()
  defp exec(conn, query, bindvars, opts) do
    Arangox.transaction(
      conn,
      fn c ->
        stream = Arangox.cursor(c, query, bindvars)
        Enum.to_list(stream)
      end,
      Keyword.merge([properties: [waitForSync: true]], opts)
    )
  end

  @spec create_collection(pid(), bitstring(), :doc | :edge) :: {:ok, bitstring()}
  defp create_collection(conn, name, type) do
    Logger.info("[Subaru.DB] Creating collection #{name}")

    typenum =
      case type do
        :doc -> 2
        :edge -> 3
      end

    # check if it exists
    case Arangox.get(conn, "/_api/collection/#{name}") do
      {:ok, %Arangox.Response{status: 200, body: %{"id" => id}}} ->
        {:ok, id}

      {:error, %Arangox.Error{status: 404}} ->
        # DNE, create.
        {:ok, response} =
          Arangox.post(conn, "/_api/collection", %{
            name: name,
            # 2 = document, 3 = edge
            type: typenum
          })

        {:ok, response.body["id"]}
    end
  end

  @spec remove_collection(pid(), bitstring()) :: {:ok, bitstring()} | {:error, :dne}
  defp remove_collection(conn, name) do
    Logger.info("[Subaru.DB] Removing collection #{name}")

    case Arangox.delete(conn, "/_api/collection/#{name}") do
      {:ok, %Arangox.Response{status: 200} = res} ->
        {:ok, res.body["id"]}

      {:error, %Arangox.Error{status: 404} = _res} ->
        {:error, :dne}
    end
  end
end
