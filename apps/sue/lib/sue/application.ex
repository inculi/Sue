defmodule Sue.Application do
  @moduledoc false

  use Application
  require Logger

  @platforms Application.get_env(:sue, :platforms, [])

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      Sue,
      Sue.DB,
      {Phoenix.PubSub, name: Sue.PubSub}
    ]

    children_imessage =
      if Sue.Utils.contains?(@platforms, :imessage) do
        # Method used to avoid strange Dialyzer error...
        [
          Sue.Mailbox.IMessage,
          worker(Sqlitex.Server, [
            Application.get_env(:sue, :chat_db_path),
            [name: Sue.IMessageChatDB]
          ])
        ]
      else
        []
      end

    children_telegram =
      if Sue.Utils.contains?(@platforms, :telegram) do
        [
          ExGram,
          {Sue.Mailbox.Telegram, [method: :polling, token: Application.get_env(:ex_gram, :token)]}
        ]
      else
        []
      end

    opts = [strategy: :one_for_one, name: Sue.Supervisor]
    Supervisor.start_link(children ++ children_imessage ++ children_telegram, opts)
  end
end
