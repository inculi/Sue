defmodule Sue.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      Sue.DB,
      Sue.Mailbox.IMessage,
      worker(Sqlitex.Server, [
        Application.get_env(:sue, :chat_db_path),
        [name: Sue.IMessageChatDB]
      ]),
      Sue
    ]

    opts = [strategy: :one_for_one, name: Sue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
