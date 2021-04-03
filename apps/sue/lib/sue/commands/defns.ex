defmodule Sue.Commands.Defns do
  @moduledoc """
  User-defined commands, currently restricted to echoing whatever value is
    stored for their command key.
  """

  # TODO: Scoped definitions.
  # TODO: re-implement #variable injection
  # TODO: User-defined lambdas

  Module.register_attribute(__MODULE__, :is_persisted, persist: true)
  @is_persisted "is persisted"

  alias Sue.Models.{Response, Message, Definition}

  def calldefn(msg) do
    # meaning = get_defn!(msg) || "Command not found. Add it with !define."

    case Definition.get(msg.command |> String.downcase(), :text, msg.chat, msg.account) do
      nil -> %Response{body: "Command not found. Add it with !define."}
      defn -> %Response{body: defn.val}
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

      [word, val] ->
        {:ok, _} = Definition.set(word |> String.downcase(), val, :text, msg.chat, msg.account)

        %Response{body: "#{word} updated."}
    end
  end
end
