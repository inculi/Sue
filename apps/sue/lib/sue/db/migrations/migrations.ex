defmodule Sue.DB.Migrations do
  @moduledoc """
  Each time I make major DB updates to Sue, I have to give these mini-tutorials
    telling other admins how to carefully transfer their data to the new ver.

  This isn't fair to them, and not fun for me, so I'd like Sue to automatically
    make the proper upgrades based on what version you were previously running
    before doing your git pull.
  """

  @collection "sue_db_migrations"

  def collection(), do: @collection

  @spec set_last_recorded_version(tuple()) :: {:ok, Subaru.dbid()}
  def set_last_recorded_version(vsn) when is_tuple(vsn) do
    Subaru.insert(
      %{
        "_key" => "0",
        "vsn" => version_tuple_to_str(vsn)
      },
      @collection
    )
  end

  @doc """
  Runs new migrations that need to be run.
  """
  def run_new_migrations() do
    current_version = version()

    last_version = get_last_recorded_version()

    if current_version > last_version do
      find_migrations_newer_than(last_version)
      |> run_migrations()

      {:ok, _} = set_last_recorded_version(current_version)
    end
  end

  @spec find_migrations_newer_than(tuple()) :: [tuple()]
  defp find_migrations_newer_than(vsn) do
    list_migrations()
    |> Enum.filter(fn {_, _, version} ->
      version > vsn
    end)
  end

  defp run_migrations(migrations) do
    migrations
    |> Enum.map(fn {module, _, _} ->
      apply(module, :run, [])
    end)
  end

  @spec get_last_recorded_version() :: {:ok, tuple()}
  defp get_last_recorded_version() do
    case Subaru.get(@collection, "0") do
      # Return {0, 0, 0} if we don't have anything recorded.
      {:ok, nil} -> {:ok, {0, 0, 0}}
      {:ok, doc} -> {:ok, vsn_to_tuple(doc["vsn"])}
    end
  end

  @spec version() :: {integer(), integer(), integer()}
  def version() do
    Application.spec(:sue, :vsn)
    |> List.to_string()
    |> vsn_to_tuple()
  end

  def vsn_to_tuple(vsn) when is_bitstring(vsn) do
    vsn
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end

  def version_tuple_to_str({v, s, n}), do: "#{v}.#{s}.#{n}"

  @spec list_migrations() :: [bitstring()]
  def list_migrations() do
    :code.all_available()
    |> Enum.map(fn {module, _, _} ->
      List.to_string(module)
    end)
    |> Enum.filter(fn m ->
      String.starts_with?(m, "Elixir.Sue.DB.Migrations.M")
    end)
    |> Enum.map(fn m ->
      "Elixir.Sue.DB.Migrations.M" <> unix_str = m
      module = String.to_atom(m)
      vsn = apply(module, :vsn, [])
      {module, DateTime.from_unix!(String.to_integer(unix_str)), vsn}
    end)
    |> Enum.sort_by(fn {_m, dt, _vsn} -> dt end, :asc)
  end
end
