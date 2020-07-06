defmodule Sue.Models.Attachment do
  alias __MODULE__

  @type t() :: %__MODULE__{}

  @tmp_path "/tmp/sue/media/"

  defstruct [
    :id,
    :message_id,
    :filename,
    :mime_type,
    :fsize
  ]

  def new(
        [a_id: aid, m_id: mid, filename: filename, mime_type: mime_type, total_bytes: fsize],
        :imessage
      ) do
    %Attachment{
      id: aid,
      message_id: mid,
      filename: filename,
      mime_type: mime_type,
      fsize: fsize
    }
  end

  def new(
        %{
          file_id: file_id,
          file_size: fsize,
          file_unique_id: file_unique_id,
          height: _height,
          width: _width
        },
        :telegram
      ) do
    file_url = ExGram.File.file_url(ExGram.get_file!(file_id))

    %Attachment{
      from_url(file_url, file_unique_id)
      | id: file_unique_id,
        mime_type: "",
        fsize: fsize
    }
  end

  def from_url(url, filename \\ Sue.Utils.unique_string()) do
    file_path = Path.join(@tmp_path, filename <> Path.extname(url))
    env = Tesla.get!(url)
    File.write!(file_path, env.body)

    %Attachment{
      filename: file_path
    }
  end
end

# AgACAgEAAxkBAAID_17ZaI3Bgu7rzpQedYhwcM-7D670AAJQqDEbOhXQRtfk4eHJcZhuFv3wSBcAAwEAAwIAA3gAA3gzAAIaBA
# AgACAgEAAxkBAAID_17ZaI3Bgu7rzpQedYhwcM-7D670AAJQqDEbOhXQRtfk4eHJcZhuFv3wSBcAAwEAAwIAA20AA3czAAIaBA
