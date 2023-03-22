defmodule Sue.Mailbox.Discord do
  use Nostrum.Consumer

  require Logger

  alias Sue.Models.{Message, Response}
  alias Nostrum.Api

  def start_link() do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, dmsg, _ws_state}) do
    # Logger.debug(dmsg |> inspect(pretty: true))
    msg = Message.from_discord(dmsg)
    Sue.process_messages([msg])
  end

  def handle_event(_event) do
    :noop
  end

  @spec send_response(Message.t(), Response.t()) :: any()
  def send_response(msg, response) do
    with {:ok, _} <- Api.create_message(msg.metadata.channel_id, response.body) do
      :ok
    else
      error -> Logger.error(error |> inspect())
    end
  end
end
