defmodule Sue.Utils do
  @spec tokenize(String.t()) :: [String.t()]
  def tokenize(args) do
    cond do
      String.contains?(args, "\n") -> String.split(args, "\n")
      String.contains?(args, ",") -> String.split(args, ",", trim: true)
      true -> String.split(args, " ")
    end
  end
end
