defmodule Sue.Commands.Defns do
  @moduledoc """
  User-defined commands, currently restricted to echoing whatever value is
    stored for their command key.
  """

  # TODO: Scoped definitions.
  # TODO: re-implement #variable injection
  # TODO: User-defined lambdas

  alias Sue.DB
  alias Sue.Models.{Response, Message}

  def calldefn(msg) do
    # meaning = get_defn!(msg) || "Command not found. Add it with !define."
    case DB.Defn.get(msg.command, msg.account, msg.chat) do
      {:ok, meaning} -> %Response{body: meaning}
      {:error, :not_found} -> %Response{body: "Command not found. Add it with !define."}
    end
  end

  @doc """
  Create a quick alias that makes Sue say something.
  Usage: !define <word> <... meaning ...>
  ---
  You: !define myword this is my definition
  Sue: myword updated.
  You: !word
  Sue: this is my definition
  """
  def c_define(%Message{args: ""}), do: %Response{body: "Please supply a word and meaning."}

  def c_define(msg) do
    case msg.args |> String.split(" ", parts: 2) do
      [_word] ->
        %Response{body: "Please supply a meaning for the word."}

      [word, defn] ->
        {:ok, _} = DB.Defn.set(word, defn, msg.account, msg.chat)
        %Response{body: "#{word} updated."}
    end
  end

  def get_defn!(%Message{} = msg) do
    {:ok, meaning} = DB.Defn.get(msg.command, msg.account, msg.chat)
    meaning
  end
end
