defmodule Sue.Utils do
  @spec tokenize(String.t()) :: [String.t()]
  def tokenize(args) do
    cond do
      String.contains?(args, "\n") -> String.split(args, "\n")
      String.contains?(args, ",") -> String.split(args, ",", trim: true)
      true -> String.split(args, " ")
    end
  end

  @spec contains?(Enumerable.t(), any()) :: boolean()
  def contains?(enum, item) do
    item in enum
  end

  def unique_string() do
    ("Reference<" <> inspect(make_ref()))
    |> String.trim_trailing(">")
  end
end
