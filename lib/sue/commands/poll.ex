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
    args = String.downcase(msg.args)

    if String.match?(args, ~r/^[a-z]$/) do
      case DB.Poll.update(msg.chat, msg.account, alpha_to_idx(args)) do
        {:ok, newpoll} ->
          poll_to_response(newpoll, msg.platform)

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

  defp create_poll(msg, [topic | choices]) when is_list(choices) and length(choices) <= 26 do
    DB.Poll.new(msg.chat, topic, choices)
    |> poll_to_response(msg.platform)
  end

  defp create_poll(_msg, _) do
    %Response{body: "Please limit to 26 options or less."}
  end

  @spec poll_to_response(Map.t(), Atom.t()) :: Response.t()
  defp poll_to_response(%{topic: topic, choices: choices, votes: votes}, :imessage) do
    # To text
    %Response{body: poll_text(topic, choices, votes)}
  end

  defp poll_to_response(%{topic: topic, choices: choices, votes: votes}, :telegram) do
    # TODO: Implement Telegram's poll object, I imagine as some form of attachment.
    %Response{body: poll_text(topic, choices, votes)}
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
