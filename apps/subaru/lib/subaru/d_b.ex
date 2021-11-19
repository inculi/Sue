defmodule Subaru.DB do
  use GenServer

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    options = [
      username: Application.fetch_env!(:arangox, :username),
      password: Application.fetch_env!(:arangox, :password)
    ]

    {:ok, conn} = Arangox.start_link(options)
    {:ok, conn, {:continue, :post_init}}
  end

  # ensure our collections and what-not are defined.
  @impl true
  def handle_continue(:post_init, conn) do
    create_collection(conn, "sue_users", :doc)
    create_collection(conn, "sue_chats", :doc)
    create_collection(conn, "sue_inChat", :edge)

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
    newid = create_collection(conn, name, type)
    {:reply, newid, conn}
  end

  # PUBLIC API
  # ==========

  def ping() do
    GenServer.call(__MODULE__, :ping)
  end

  def insert(doc, collection) do
    GenServer.call(__MODULE__, {:insert, doc, collection})
  end

  def insert_edge(fromid, toid, collection) do
    GenServer.call(__MODULE__, {:insert_edge, fromid, toid, collection})
  end

  def list(collection) do
    GenServer.call(__MODULE__, {:list, collection})
  end

  def conn() do
    GenServer.call(__MODULE__, :conn)
  end

  @spec create_collection(String.t(), :doc | :edge) :: String.t()
  def create_collection(name, type) do
    GenServer.call(__MODULE__, {:create_collection, name, type})
  end

  # HELPER UTILS
  # ============

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

  @spec create_collection(pid(), String.t(), :doc | :edge) :: String.t()
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
        id

      {:error, %Arangox.Error{status: 404}} ->
        # DNE, create.
        {:ok, response} =
          Arangox.post(conn, "/_api/collection", %{
            name: name,
            # 2 = document, 3 = edge
            type: typenum
          })

        response.body["id"]
    end
  end
end
