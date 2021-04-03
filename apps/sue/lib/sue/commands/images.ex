defmodule Sue.Commands.Images do
  Module.register_attribute(__MODULE__, :is_persisted, persist: true)
  @is_persisted "is persisted"
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
      path =
        if String.starts_with?(att.filename, "~") do
          Path.expand(att.filename)
        else
          Path.absname(att.filename)
        end

      %Attachment{filename: path}
    else
      %Response{body: "!meme only supports images right now, sorry :("}
    end
  end

  def c_meme(%Message{has_attachments: false}) do
    %Response{body: "Failed to detect attachment. Falling back to last image."}
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

  defp is_image?(%Attachment{mime_type: mime_type}) when is_bitstring(mime_type) do
    mime_type |> String.starts_with?("image/")
  end
end
