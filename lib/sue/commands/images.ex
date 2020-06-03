defmodule Sue.Commands.Images do
  Module.register_attribute(__MODULE__, :is_persisted, persist: true)
  @is_persisted "is persisted"
  alias Sue.Models.Attachment

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
end
