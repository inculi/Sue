defmodule Sue.Models.Attachment do
  alias __MODULE__
  alias Sue.Models.Platform

  @type t() :: %__MODULE__{}

  # 20MiB
  @max_attachment_size_bytes 20 * 1024 * 1024
  @tmp_path System.tmp_dir!()

  defstruct [
    :id,
    :message_id,
    :filename,
    :mime_type,
    :fsize,
    resolved: false,
    errors: [],
    metadata: %{}
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
      fsize: fsize,
      resolved: true
    }
  end

  def new(
        %{
          file_id: file_id,
          file_size: fsize,
          file_unique_id: file_unique_id
        } = data,
        :telegram
      ) do
    file_url = ExGram.File.file_url(ExGram.get_file!(file_id))

    %Attachment{
      id: file_unique_id,
      fsize: fsize,
      resolved: false,
      errors: check_size_for_errors(fsize) ++ [],
      mime_type: Map.get(data, :mime_type, "image/jpeg"),
      metadata: %{url: file_url}
    }
  end

  @spec resolve(Attachment.t(), Platform.t()) :: {:ok | :error, Attachment.t()}
  def resolve(%Attachment{resolved: true} = att, _), do: {:ok, att}
  def resolve(%Attachment{errors: [_]} = att, _), do: {:error, att}

  def resolve(att, :telegram) do
    att_filepath = from_url(att.metadata.url, att.id).filename

    {:ok,
     %Attachment{
       att
       | resolved: true,
         filename: att_filepath
     }}
  end

  @spec from_url(binary, binary) :: Sue.Models.Attachment.t()
  def from_url(url, filename \\ Sue.Utils.unique_string()) do
    file_path = Path.join(@tmp_path, filename <> Path.extname(url))
    env = Tesla.get!(url)
    File.write!(file_path, env.body)

    %Attachment{
      filename: file_path
    }
  end

  # TODO: Have some part of the message processing pipeline that can detect if
  #   we are processing a message with an attachment with an error and warn the
  #   user as soon as we detect this.
  defp check_size_for_errors(fsize) do
    if fsize > @max_attachment_size_bytes do
      [{:size, "File size is #{@max_attachment_size_bytes - fsize} bytes too big."}]
    else
      []
    end
  end

  def is_too_large?(att) do
    att.fsize > @max_attachment_size_bytes
  end
end
