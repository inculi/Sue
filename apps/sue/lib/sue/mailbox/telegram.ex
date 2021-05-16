defmodule Sue.Mailbox.Telegram do
  @bot :sue
  @dialyzer [
    {:no_return, [init: 1, maybe_setup_commands: 3, maybe_fetch_bot: 2]},
    {:no_unused,
     [regexes: 0, middlewares: 0, maybe_fetch_bot: 2, handle_error_mf: 0, handle_mf: 0]}
  ]
  @pretty_debug false

  require Logger

  alias Sue.Models.{Message, Response}

  use ExGram.Bot,
    name: @bot

  def bot(), do: @bot

  def handle({:command, command, msg}, context) do
    Logger.debug("=== begin :command handle ===")
    Logger.debug("command: #{command |> inspect(pretty: @pretty_debug)}")
    Logger.debug("msg: #{msg |> inspect(pretty: @pretty_debug)}")
    Logger.debug("context: #{context |> inspect(pretty: @pretty_debug)}")
    Logger.debug("=== end :command handle ===")

    # Logger.info("msg: #{inspect(msg)}\n\ncontext: #{inspect(context)}")
    msg = Message.new(:telegram, %{msg: msg, command: command, context: context})
    Sue.process_messages([msg])
    context
  end

  def handle({:message, msg}, context) do
    Logger.debug("=== begin :message handle ===")
    Logger.debug("msg: #{msg |> inspect(pretty: @pretty_debug)}")
    Logger.debug("context: #{context |> inspect(pretty: @pretty_debug)}")
    Logger.debug("=== end :message handle ===")
    # Logger.info("msg: #{inspect(msg)}\n\ncontext: #{inspect(context)}")
    msg = Message.new(:telegram, %{msg: msg, context: context})
    Sue.process_messages([msg])
    context
  end

  # def handle({:text, text, msg}, _context) do
  #   # Direct text or reply in group
  #   # Logger.info("text: #{inspect(text)}\nmsg: #{inspect(msg)}\n\ncontext: #{inspect(context)}")
  #   :ok
  # end

  # def handle({:update, update}, _context) do
  #   # Poll responses
  #   :ok
  # end

  def send_response(_msg, %Response{body: nil, attachments: []}) do
    # Likely already sent custom response (ex: polls)
    :ok
  end

  def send_response(%Message{} = msg, %Response{attachments: []} = rsp) do
    # No attachments
    send_response_text(msg, rsp)
  end

  def send_response(msg, %Response{body: nil, attachments: atts}) do
    # No text
    send_response_attachments(msg, atts)
  end

  def send_response(%Message{} = msg, %Response{attachments: atts} = rsp) do
    send_response_text(msg, rsp)
    send_response_attachments(msg, atts)
  end

  def send_response_text(msg, rsp) do
    ExGram.send_message(msg.chat.id, rsp.body)
    :ok
  end

  def send_response_attachments(_msg, []), do: :ok

  def send_response_attachments(msg, [att | atts]) do
    ExGram.send_photo(msg.chat.id, {:file, att.filename})
    send_response_attachments(msg, atts)
  end
end
