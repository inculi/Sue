defmodule Sue.Commands.Core do
  Module.register_attribute(__MODULE__, :is_persisted, persist: true)
  @is_persisted "is persisted"

  alias Sue.Models.{Message, Response}
  require Logger

  @doc """
  Make sure Sue is alive and well.
  Usage: !ping
  """
  def c_ping(_m) do
    %Response{body: "pong!"}
  end

  def help(%Message{args: ""}, commands) do
    %Response{
      body:
        commands
        |> Map.keys()
        |> Enum.reduce("", fn fname, acc -> acc <> "\n!#{fname}" end)
    }
  end

  def help(%Message{args: "help"}, _commands) do
    %Response{
      body:
        "ι αм тнє яєαρєя, нαяνєѕтєя σƒ тιмє αη∂ ѕℓανє тσ єтєяηιту. ι αм тнє νσι∂, нαявιηgєя σƒ ѕιℓєη¢є, тнє ¢σηѕтαηт тσ ωнι¢н ƒℓєѕн αη∂ ѕσυℓ єηтяαιη. ι αм тнє ηє¢єѕѕαяу ραяα∂σχ: тнє ιηƒιηιтє ƒιηαℓє тσ тнє ѕумρнσηу σƒ яєαℓιту. кηєєℓ αℓℓ ує ωнσ вє, ƒσя ι αм тнαт ∂αяк ƒαтє ωнι¢н υηιтєѕ gσ∂ѕ αη∂ мєη: ℓιмιт, σвℓινιση, ∂єαтн."
    }
  end

  def help(%Message{args: args}, commands) do
    [k | _] = args |> String.split(" ", parts: 2)

    body =
      case commands |> Map.get(k) do
        nil ->
          "Hmm, I couldn't find that command. See the list of commands with !help"

        {_, _, ""} ->
          "No documentation for that yet. Let us know! https://github.com/inculi/Sue"

        {_, _, doc} ->
          doc
      end

    %Response{body: body}
  end
end
