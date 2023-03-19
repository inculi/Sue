defmodule Sue.Application do
  @moduledoc false

  use Application
  require Logger

  @platforms Application.compile_env(:sue, :platforms, [])
  @chat_db_path Application.compile_env(:sue, :chat_db_path)
  @ex_gram_token Application.compile_env(:ex_gram, :token)

  def start(_type, _args) do
    children = [
      Sue,
      Sue.DB
    ]

    Logger.info(@chat_db_path |> inspect())

    children_imessage =
      if Sue.Utils.contains?(@platforms, :imessage) do
        # Method used to avoid strange Dialyzer error...
        [
          %{
            id: Sqlitex.Server,
            start: {Sqlitex.Server, :start_link, [@chat_db_path, [name: Sue.IMessageChatDB]]}
          },
          Sue.Mailbox.IMessage
        ]
      else
        []
      end

    children_telegram =
      if Sue.Utils.contains?(@platforms, :telegram) do
        [
          ExGram,
          {Sue.Mailbox.Telegram, [method: :polling, token: @ex_gram_token]}
        ]
      else
        []
      end

    opts = [strategy: :one_for_one, name: Sue.Supervisor]
    Supervisor.start_link(children ++ children_imessage ++ children_telegram, opts)
  end
end
