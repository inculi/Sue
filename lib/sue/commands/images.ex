defmodule Sue.Commands.Images do
  alias Sue.Models.{Attachment, Response}

  @media_path Path.join(:code.priv_dir(:sue), "media/")

  @doc """
  Shows a picture of a cute doog.
  Usage: !doog
  """
  def c_doog(_msg) do
    %Response{
      attachments: [
        %Attachment{
          filename: Path.join(@media_path, "korone.JPG")
        }
      ]
    }
  end
end
