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

  @doc """
  Create a motivational poster.
  Usage: !motivate <image> <top text>, <bottom text>
  (bottom text is optional)
  """
  def c_motivate(%Message{has_attachments: false}) do
    %Response{body: "Please include an image with your message. See !help motivate"}
  end

  def c_motivate(%Message{has_attachments: true, attachments: [att | _]} = msg) do
    # only process the first attachment.
    cond do
      is_image?(att) and not Attachment.is_too_large?(att) ->
        {:ok, att} = Attachment.resolve(att, :telegram)
        path = resolve_filepath(att.filename)

        {top_text, bot_text} =
          case String.split(msg.args, ~r{,}, parts: 2, trim: true) |> Enum.map(&String.trim/1) do
            [] -> {nil, nil}
            [top] -> {top, ""}
            [top, bot] -> {top, bot}
          end

        motivate_helper(path, top_text, bot_text)

      Attachment.is_too_large?(att) ->
        %Response{body: "Media is too large. Please try again with a smaller file."}

      true ->
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
