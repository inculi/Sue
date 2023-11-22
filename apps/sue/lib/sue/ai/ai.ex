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

  @spec chat_completion(bitstring(), :gpt35 | :gpt4) :: bitstring()
  def chat_completion(text, modelversion) when is_atom(modelversion) do
    model =
      case modelversion do
        :gpt35 -> "gpt-3.5-turbo"
        :gpt4 -> "gpt-4"
      end

    Logger.debug("Running chat_completion with #{model}")

    with {:ok, response} <-
           OpenAI.chat_completion(
             model: model,
             messages: [
               %{role: "user", content: text}
             ]
           ) do
      [%{"message" => %{"content" => content}}] = response.choices
      content |> String.trim("\n")
    else
      {:error, :timeout} ->
        "Sorry, I timed out. Please try later, maybe additionally asking I keep my response short."

      {:error, %{"status" => status_message}} ->
        Logger.error("[Sue.AI.chat_completion()] #{status_message}")
        status_message

      {:error, %{"message" => status_message}} ->
        Logger.error("[Sue.AI.chat_completion()] #{status_message}")
        status_message
    end
  end

  @doc """
  Huge thanks to https://github.com/cbh123/emoji for this.
  """
  @spec gen_image_emoji(bitstring()) :: {:ok | :error, bitstring()}
  def gen_image_emoji(prompt) do
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

    Replicate.Predictions.wait(prediction)
    |> process_image_output()
  end

  @spec gen_image_sd(bitstring()) :: {:ok | :error, bitstring()}
  def gen_image_sd(prompt) do
    model = Replicate.Models.get!("stability-ai/sdxl")

    version =
      Replicate.Models.get_version!(
        model,
        "8beff3369e81422112d93b89ca01426147de542cd4684c244b673b105188fe5f"
      )

    {:ok, prediction} =
      Replicate.Predictions.create(version, %{
        prompt: prompt,
        width: 768,
        height: 768,
        num_inference_steps: 30
      })

    Replicate.Predictions.wait(prediction)
    |> process_image_output()
  end

  defp process_image_output({:ok, %Replicate.Predictions.Prediction{error: nil, output: [url]}}) do
    {:ok, url}
  end

  defp process_image_output({:ok, %Replicate.Predictions.Prediction{error: error_msg}}) do
    {:error, error_msg}
  end
end
