defmodule Sue.Models.Response do
  alias __MODULE__

  @type t() :: %__MODULE__{}
  defstruct [
    :body,
    attachments: []
  ]

  defimpl String.Chars, for: Response do
    def to_string(%Response{body: body, attachments: [%Sue.Models.Attachment{} | _]}) do
      "#Response<body:'#{body}',:has_media>"
    end

    def to_string(%Response{body: body}) do
      "#Response<body:'#{body}'>"
    end
  end
end
