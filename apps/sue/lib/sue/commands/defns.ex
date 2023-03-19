defmodule Sue.Commands.Defns do
  @moduledoc """
  User-defined commands, currently restricted to echoing whatever value is
    stored for their command key.
  """

  # TODO: re-implement #variable injection
  # TODO: User-defined lambdas

  Module.register_attribute(__MODULE__, :is_persisted, persist: true)
  @is_persisted "is persisted"

  alias Sue.Models.{Response, Message}
  alias Sue.New.{DB, Defn}

  def calldefn(msg) do
    # meaning = get_defn!(msg) || "Command not found. Add it with !define."
    varname = msg.command

    case DB.find_defn(msg.account.id, msg.chat.id, varname) do
      {:ok, %Defn{val: val}} -> %Response{body: val}
      {:error, :dne} -> %Response{body: "Command not found. Add it with !define."}
    end
  end

  @spec c_define(atom | %{:args => binary, optional(any) => any}) :: Sue.Models.Response.t()
  @doc """
  Create a quick alias that makes Sue say something.
  Usage: !define <word> <... meaning ...>
  ---
  You: !define myword this is my definition
  Sue: myword updated.
  You: !myword
  Sue: this is my definition
  """
  def c_define(%Message{args: ""}),
    do: %Response{body: "Please supply a word and meaning. See !help define"}

  def c_define(msg) do
    case msg.args |> String.split(" ", parts: 2) do
      [_word] ->
        %Response{body: "Please supply a meaning for the word. See !help define"}

      [word, val] ->
        var = word |> String.downcase()

        {:ok, _} =
          Defn.new(var, val, :text)
          |> DB.add_defn(msg.account.id, msg.chat.id)

        %Response{body: "#{var} updated."}
    end
  end
end
