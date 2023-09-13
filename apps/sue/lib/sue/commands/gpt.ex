defmodule Sue.Commands.Gpt do
  alias Sue.Models.{Message, Response, Attachment}

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

  def c_emoji(%Message{args: ""}) do
    %Response{body: "What is your emoji? Ex: !emoji a grilled cheese"}
  end

  def c_emoji(%Message{args: prompt}) do
    url = Sue.AI.gen_image(prompt)
    %Response{attachments: [Attachment.from_url(url)]}
  end
end
