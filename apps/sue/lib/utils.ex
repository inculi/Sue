defmodule Sue.Utils do
  def quoted(s) when is_bitstring(s) do
    "\"#{s}\""
  end

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
    :os.timestamp()
    |> :erlang.phash2()
    |> Integer.to_string()
  end

  def tmp_file_name(suffix) when is_bitstring(suffix) do
    prefix = "#{:os.getpid()}-#{random_string()}-"
    prefix <> suffix
  end

  @spec unix_now() :: integer()
  def unix_now() do
    DateTime.utc_now() |> DateTime.to_unix()
  end

  def random_string do
    Integer.to_string(rand_uniform(0x100000000), 36) |> String.downcase()
  end

  if :erlang.system_info(:otp_release) >= '18' do
    defp rand_uniform(num) do
      :rand.uniform(num)
    end
  else
    defp rand_uniform(num) do
      :random.uniform(num)
    end
  end

  def struct_to_map(s) do
    s
    |> Map.from_struct()
    |> Map.drop([:id])
  end

  @spec string_to_atom(atom | bitstring()) :: atom
  def string_to_atom(s) when is_bitstring(s), do: String.to_atom(s)
  def string_to_atom(a) when is_atom(a), do: a
end
