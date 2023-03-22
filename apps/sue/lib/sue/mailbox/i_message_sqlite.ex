defmodule Sue.Mailbox.IMessageSqlite do
  use GenServer
  require Logger

  def start_link(args) do
    Logger.info("Starting Sqlite genserver...")
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init([chat_db_path]) do
    {:ok, _conn} = Exqlite.Sqlite3.open(chat_db_path)
  end

  @impl true
  def handle_call({:query, query}, _from, conn) do
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, query)
    {:ok, rows} = Exqlite.Sqlite3.fetch_all(conn, statement)

    {:reply, rows, conn}
  end

  def query(q) do
    GenServer.call(__MODULE__, {:query, q})
  end
end
