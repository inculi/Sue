defmodule Sue.Mailbox.IMessageSqlite do
  use GenServer
  require Logger

  def start_link(args) do
    Logger.info("Starting Sqlite genserver...")
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init([chat_db_path]) do

  end
end
