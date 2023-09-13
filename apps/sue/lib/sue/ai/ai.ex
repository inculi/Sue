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
    with {:ok, response} <-
           OpenAI.chat_completion(
             model: "gpt-3.5-turbo",
             messages: [
               %{role: "user", content: text}
             ]
           ) do
      [%{"message" => %{"content" => content}}] = response.choices
      content |> String.trim("\n")
    else
      {:error, :timeout} ->
        "Sorry, I timed out. Please try later, maybe additionally asking I keep my response short."
    end
  end

  def gen_image(prompt) do
    model = Replicate.Models.get!("fofr/sdxl-emoji")

    version =
      Replicate.Models.get_version!(
        model,
        "4d2c2e5e40a5cad182e5729b49a08247c22a5954ae20356592caaada42dc8985"
      )

    {:ok, prediction} =
      Replicate.Predictions.create(version, %{
        prompt: "A TOK emoji of " <> prompt,
        width: 768,
        height: 768,
        num_inference_steps: 30
      })

    {:ok, %Replicate.Predictions.Prediction{output: [url]}} =
      Replicate.Predictions.wait(prediction)

    url
  end
end
