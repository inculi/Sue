defmodule Sue.AI do
  use GenServer

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok, []}
  end

  @spec chat_completion(bitstring()) :: bitstring()
  def chat_completion(text) do
    {:ok, response} =
      OpenAI.chat_completion(
        model: "gpt-3.5-turbo",
        messages: [
          %{role: "user", content: text}
        ]
      )

    # I'm assuming there will only be one choice.
    [%{"message" => %{"content" => content}}] = response.choices
    content |> String.trim("\n")
  end
end
