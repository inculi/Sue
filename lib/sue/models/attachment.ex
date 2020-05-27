defmodule Sue.Models.Attachment do
  alias __MODULE__

  @type t() :: %__MODULE__{}

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
end
