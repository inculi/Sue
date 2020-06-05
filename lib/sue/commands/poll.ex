defmodule Sue.Commands.Poll do
  Module.register_attribute(__MODULE__, :is_persisted, persist: true)
  @is_persisted "is persisted"
  alias Sue.Models.{Message, Response}
  alias Sue.DB

  @doc """
  Create a poll for people to !vote on.
  Usage: !poll which movie?
  grand budapest
  tron
  bee movie
  """
  def c_poll(%Message{args: ""}) do
    %Response{body: "Please specify a poll topic with options."}
  end

  def c_poll(msg) do
    poll_args = Sue.Utils.tokenize(msg.args)
    create_poll(msg, poll_args)
  end

  @doc """
  Vote on an ongoing poll
  Usage: !vote a
  """
  def c_vote(msg) do
    case DB.Poll.get(msg.chat) do
      {:ok, :custom} ->
        %Response{body: "Please use this messenger's custom polling interface."}

      {:ok, nil} ->
        %Response{body: "A poll does not exist for this chat."}

      {:ok, _poll} ->
        vote(msg)
    end
  end

  def vote(msg) do
    args = String.downcase(msg.args)

    if String.match?(args, ~r/^[a-z]$/) do
      case DB.Poll.update(msg.chat, msg.account, alpha_to_idx(args)) do
        {:ok, newpoll} ->
          poll_to_response(newpoll, msg)

        {:error, reason} ->
          %Response{body: reason}
      end
    else
      %Response{body: "Not an option in this poll. See: !help vote"}
    end
  end

  defp create_poll(_msg, [_]) do
    %Response{body: "Please specify options for the poll. See !help poll"}
  end

  defp create_poll(msg, [topic | choices])
       when is_list(choices) and length(choices) <= 26 do
    cond do
      # Telegram's custom polling interface requires 10 options or less.
      msg.platform == :telegram and length(choices) <= 10 ->
        DB.Poll.new_custom(msg.chat, topic, choices)
        |> poll_to_response(msg)

      true ->
        DB.Poll.new(msg.chat, topic, choices)
        |> poll_to_response(msg)
    end
  end

  defp create_poll(_msg, _) do
    %Response{body: "Please limit to 26 options or less."}
  end

  @spec poll_to_response(Map.t(), Message.t()) :: Response.t()
  defp poll_to_response(%{topic: topic, choices: choices, votes: votes}, %Message{
         platform: :imessage
       }) do
    # To text
    %Response{body: poll_text(topic, choices, votes)}
  end

  defp poll_to_response(%{topic: topic, choices: choices, votes: votes} = poll, %Message{
         platform: :telegram,
         chat: chat
       }) do
    if length(choices) > 10 do
      # Resort to typical poll interface
      %Response{body: poll_text(topic, choices, votes)}
    else
      # Use Telegram's custom interface.
      poll
      |> (fn %{topic: topic, choices: choices} ->
            ExGram.send_poll(chat.id, topic, choices, is_anonymous: false)
          end).()

      %Response{}
    end
  end

  defp poll_text(topic, choices, votes) when map_size(votes) == 0 do
    ([topic] ++
       (Enum.with_index(choices)
        |> Enum.map(fn {choice, idx} ->
          "#{idx_to_alpha(idx)}. #{choice}"
        end)))
    |> Enum.join("\n")
  end

  defp poll_text(topic, choices, votes) do
    votes_vk =
      votes
      |> Map.to_list()
      |> Enum.group_by(fn {_k, v} -> v end, fn {k, _v} -> k end)

    ([topic] ++
       (Enum.with_index(choices)
        |> Enum.map(fn {choice, idx} ->
          choice_votes = Map.get(votes_vk, idx, []) |> length()
          "(#{choice_votes}) #{idx_to_alpha(idx)}. #{choice}"
        end)))
    |> Enum.join("\n")
  end

  defp idx_to_alpha(idx) when is_integer(idx) and idx >= 0 and idx <= 26 do
    <<97 + idx>>
  end

  defp alpha_to_idx(alpha) when is_bitstring(alpha) do
    <<idx>> = alpha
    idx - 97
  end
end
