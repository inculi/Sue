defmodule Sue.Commands.Poll do
  Module.register_attribute(__MODULE__, :is_persisted, persist: true)
  @is_persisted "is persisted"
  alias Sue.Models.{Message, Response}

  @doc """
  Create a poll for people to !vote on.
  Usage: !poll which movie?
  grand budapest
  tron
  bee movie
  """
  def c_poll(%Message{args: ""}) do
    %Response{body: "Please specify a poll topic with options."}
  end

  def c_poll(msg) do
    poll_args = Sue.Utils.tokenize(msg.args)
    create_poll(msg, poll_args)
  end

  defp create_poll(_msg, [_]) do
    %Response{body: "Please specify options for the poll. See !help poll"}
  end

  defp create_poll(msg, [topic, choices]) do
    {msg, topic, choices}
    %Response{body: "to be implemented."}
  end
end
