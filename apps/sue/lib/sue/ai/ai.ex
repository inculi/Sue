defmodule Sue.AI do
  use GenServer

  require Logger

  alias Sue.Models.{Chat, Account}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok, []}
  end

  @spec chat_completion(bitstring(), :gpt35 | :gpt4, Chat.t(), Account.t()) :: bitstring()
  def chat_completion(text, modelversion, chat, account)
      when is_atom(modelversion) do
    model =
      case modelversion do
        :gpt35 -> "gpt-3.5-turbo"
        :gpt4 -> "gpt-4-turbo-preview"
      end

    Logger.debug("Running chat_completion with #{model}")

    maxlen = if account.is_premium, do: 4_000, else: 1_000

    system_content_suffix =
      if chat.is_direct do
        " one other user."
      else
        " 2+ other users."
      end

    messages =
      [
        %{
          role: "system",
          content:
            "You are a helpful assistant in a group chat with a chatbot named Sue and" <>
              system_content_suffix
        }
      ] ++
        recent_messages_for_context(chat.id, chat.is_direct, text, maxlen) ++
        [
          %{
            role: "user",
            content: "#{Account.friendly_name(account) |> format_user_id()} said " <> text
          }
        ]

    Logger.debug(messages |> inspect(pretty: true))

    with {:ok, response} <-
           OpenAI.chat_completion(
             model: model,
             messages: messages
           ) do
      [%{"message" => %{"content" => content}}] = response.choices
      Logger.debug("GPT response: " <> content)
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

  defp remove_sue_prefix(str) do
    Regex.replace(~r/^\((as )?sue\)\s*/i, str, "")
  end

  @spec recent_messages_for_context(Subaru.dbid(), boolean(), bitstring(), integer()) :: [map()]
  defp recent_messages_for_context(chat_id, _is_direct, text, maxlen) do
    Sue.DB.RecentMessages.get_tail(chat_id)
    |> reduce_recent_messages(String.length(text), maxlen)
    |> Enum.map(fn %{is_from_gpt: is_from_gpt, is_from_sue: is_from_sue} = m ->
      role = if is_from_gpt, do: "assistant", else: "user"

      content_prefix =
        cond do
          is_from_gpt ->
            ""

          is_from_sue ->
            # "(as Sue) "
            "SueBot said "

          true ->
            format_user_id(m.name) <> " said "
        end

      %{role: role, content: content_prefix <> m.body}
    end)
  end

  defp format_user_id("sue_users/" <> user_id) do
    "User" <> user_id
  end

  defp format_user_id(otherwise), do: otherwise

  @spec reduce_recent_messages([map()], integer(), integer()) :: {integer(), [map()]}
  defp reduce_recent_messages(recent_messages, promptlen, maxlen) do
    {_chars_used, messages} =
      Enum.reduce_while(recent_messages, {promptlen, []}, fn m, acc ->
        {len, msgs} = acc
        newlen = len + String.length(m.body)

        if newlen <= maxlen do
          {:cont, {newlen, msgs ++ [m]}}
        else
          {:halt, acc}
        end
      end)

    messages
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
