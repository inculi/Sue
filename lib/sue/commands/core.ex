defmodule Sue.Commands.Core do
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

    case commands |> Map.get(k) do
      nil ->
        %Response{
          body: "Hmm, I couldn't find that command. See the list of commands with !help"
        }

      {module, fname} ->
        fname_a = String.to_atom("c_" <> fname)

        {_, _, _, _, _, _, docs} = Code.fetch_docs(module)
        body = find_doc(fname_a, docs)
        %Response{body: body}
    end
  end

  defp find_doc(fname_a, []) do
    Logger.error("[Sue.find_doc] Improper searching of module docs for command: #{fname_a}")

    "Hmm, I couldn't find that command. See the list of commands with !help"
  end

  defp find_doc(fname_a, [{{:function, fname_a, _}, _, _, :none, _} | _docs]) do
    "No documentation for that yet. Let us know! https://github.com/inculi/Sue"
  end

  defp find_doc(fname_a, [{{:function, fname_a, _}, _, _, %{"en" => doc}, _} | _]) do
    doc
  end

  defp find_doc(fname_a, [{{:function, _, _}, _, _, _, _} | docs]) do
    find_doc(fname_a, docs)
  end
end
