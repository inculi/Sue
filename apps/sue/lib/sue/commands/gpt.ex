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

  @doc """
  Prompt an emoji-finetuned stable diffusion model.
  Usage: !emoji Ryan Gosling
  """
  def c_emoji(%Message{args: ""}) do
    %Response{body: "What is your emoji? Ex: !emoji a grilled cheese"}
  end

  def c_emoji(%Message{args: prompt}) do
    with {:ok, url} <- Sue.AI.gen_image_emoji(prompt) do
      %Response{attachments: [Attachment.from_url(url)]}
    else
      {:error, error_msg} -> %Response{body: error_msg}
    end
  end

  @doc """
  Generate an image using stable diffusion.
  Usage: !sd a cactus shaped snowflake
  """
  def c_sd(%Message{args: ""}) do
    %Response{body: "Please provide a prompt for Stable Diffusion. See !help sd"}
  end

  def c_sd(%Message{args: prompt}) do
    with {:ok, url} <- Sue.AI.gen_image_sd(prompt) do
      %Response{attachments: [Attachment.from_url(url)]}
    else
      {:error, error_msg} -> %Response{body: error_msg}
    end
  end
end
