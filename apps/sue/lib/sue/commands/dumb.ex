defmodule Sue.Commands.Dumb do
  @moduledoc """
  I suppose I'll just put dumb lil things in here.
  """

  alias Sue.Models.Response

  def c_rub(_msg) do
    now = Timex.local()
    weekday = Timex.weekday(now)
    dtr = Integer.mod(3 - weekday, 7)
    ms = calc_microseconds(dtr, now)

    {:ok, relative} =
      now
      |> Timex.shift(microseconds: ms)
      |> Timex.format("{relative}", :relative)

    %Response{body: rub_response(ms, relative)}
  end

  def calc_microseconds(0, _now), do: 0

  def calc_microseconds(dtr, now) when dtr <= 6 do
    now
    |> Timex.to_date()
    |> Timex.add(Timex.Duration.from_days(dtr))
    |> Timex.to_datetime(Timex.Timezone.Local.lookup())
    |> Timex.diff(now, :microseconds)
  end

  def rub_response(0, _) do
    "It's rubbing day!\n" <>
      ([
         "https://www.youtube.com/watch?v=l2fKbktcyIs",
         "https://www.youtube.com/watch?v=GyhLj-YdJW4",
         "https://www.youtube.com/watch?v=k4IJROgvWHc",
         "https://www.youtube.com/watch?v=ShXmOdYGuG8",
         "https://www.youtube.com/watch?v=ET5X4voZsag"
       ]
       |> Enum.random())
  end

  def rub_response(ms, relative) do
    hours = ms / 3.6e9
    days = hours / 24

    ([
       "#{ms} microseconds",
       "#{round(ms / 1_000_000_000)} ice hockey periods",
       "#{trunc(960 * hours)} human breaths",
       "#{:erlang.float_to_binary(days / 12, decimals: 2)} Virginian opossum gestation periods"
     ]
     |> Enum.random()) <> " until rubbing day.\n(#{relative})"
  end
end
