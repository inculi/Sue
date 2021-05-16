defmodule Sue.Commands.Images do
  alias __MODULE__
  Module.register_attribute(__MODULE__, :is_persisted, persist: true)
  @is_persisted "is persisted"

  require Logger
  alias Sue.Models.{Attachment, Response, Message}

  @media_path Path.join(:code.priv_dir(:sue), "media/")

  @doc """
  Shows a picture of a cute doog.
  Usage: !doog
  """
  def c_doog(_msg) do
    %Attachment{filename: Path.join(@media_path, "korone.JPG")}
  end

  @doc """
  Snap!
  """
  def c_cringe(_msg), do: random_image_from_dir("cringe/")

  @doc """
  Sends a cute photo.
  """
  def c_qt(_msg), do: random_image_from_dir("qt/")

  def c_meme(%Message{has_attachments: true, attachments: [att | _]}) do
    # only process the first attachment.
    if is_image?(att) do
      path = resolve_filepath(att.filename)
      %Attachment{filename: path}
    else
      %Response{body: "!meme only supports images right now, sorry :("}
    end
  end

  def c_meme(%Message{has_attachments: false}) do
    %Response{body: "Failed to detect attachment. Falling back to last image."}
  end

  def c_motivate(%Message{has_attachments: false}) do
    %Response{body: "Please include an image with your message. See !help motivate"}
  end

  def c_motivate(%Message{has_attachments: true, attachments: [att | _]} = msg) do
    # only process the first attachment.
    if is_image?(att) do
      path = resolve_filepath(att.filename)

      {top_text, bot_text} =
        case String.split(msg.args, ~r{,}, parts: 2, trim: true) |> Enum.map(&String.trim/1) do
          [] -> {nil, nil}
          [top, []] -> {top, ""}
          [top, bot] -> {top, bot}
        end

      motivate_helper(path, top_text, bot_text)
    else
      %Response{body: "!motivate only supports images right now, sorry :("}
    end
  end

  defp motivate_helper(_path, nil, nil) do
    %Response{
      body:
        "Please provide a caption in the form of: !motivate top text, bottom text. The bottom text is optional."
    }
  end

  defp motivate_helper(path, top_text, bot_text) do
    Logger.debug("Top: #{top_text}, Bot: #{bot_text}")
    outpath = Images.Motivate.run(path, top_text, bot_text)
    %Attachment{filename: outpath}
  end

  @spec random_image_from_dir(String.t()) :: Attachment.t()
  defp random_image_from_dir(dir) do
    path = Path.join(@media_path, dir)

    path
    |> File.ls!()
    |> Enum.random()
    |> (fn image ->
          %Attachment{filename: Path.join(path, image)}
        end).()
  end

  defp resolve_filepath(maybe_path) do
    if String.starts_with?(maybe_path, "~") do
      Path.expand(maybe_path)
    else
      Path.absname(maybe_path)
    end
  end

  defp is_image?(%Attachment{mime_type: mime_type}) when is_bitstring(mime_type) do
    mime_type |> String.starts_with?("image/") and not (mime_type |> String.ends_with?("gif"))
  end
end
