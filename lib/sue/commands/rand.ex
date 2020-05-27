defmodule Sue.Commands.Rand do
  alias Sue.Models.{Message, Response}

  @doc """
  Flip a coin. Will return heads or tails.
  Usage: !flip
  """
  def c_flip(_msg) do
    %Response{body: ["heads", "tails"] |> Enum.random()}
  end

  @doc """
  Returns a random object in your space-delimited argument.
  Usage: !choose up down left right
  """
  def c_choose(%Message{args: args}) do
    %Response{
      body:
        args
        |> String.split(" ")
        |> Enum.random()
    }
  end

  @doc """
  Returns a random number between two positive integers.
  Usage: !random 1 10

  Return a random letter between two letters
  Usage: !random a z

  Return a random floating point number between 0 and 1 (0.47655569922929364)
  Usage: !random
  """
  def c_random(%Message{args: args}) do
    res =
      cond do
        args == "" ->
          :random.uniform() |> to_string()

        String.match?(args, ~r/^[0-9]+ [0-9]+$/u) ->
          args
          |> String.split(" ")
          |> Enum.map(&String.to_integer/1)
          |> Enum.sort()
          |> rand_range()
          |> to_string

        String.match?(args |> String.downcase(), ~r/^[a-z] [a-z]$/) ->
          with <<l, 32, r>> <- args |> String.downcase() do
            [l, r]
            |> Enum.sort()
            |> rand_range()
            |> (fn i -> <<i>> end).()
          end

        true ->
          "I couldn't figure out what you were asking. See !help random"
      end

    %Response{body: res}
  end

  defp rand_range([l, h]) do
    ((:rand.uniform() * (h - l)) |> trunc()) + l
  end
end
