defmodule Sue.Commands.Gpt do
  alias Sue.Models.{Message, Response}

  @doc """
  Asks ChatGPT a question.
  Usage: !gpt write a poem about a bot named sue
  """
  def c_gpt(%Message{args: ""}) do
    %Response{body: "Please provide a request to ChatGPT. See !help gpt"}
  end

  def c_gpt(%Message{args: args}) do
    %Response{body: Sue.AI.chat_completion(args)}
  end
end
