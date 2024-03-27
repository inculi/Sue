defmodule Subaru.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @database_name Application.compile_env!(:subaru, :dbname)

  @impl true
  def start(_type, _args) do
    children = [{Subaru.DB, [@database_name]}] ++ cachex_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Subaru.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # TODO: Make it so that it generates a cache according to an inputted schema,
  #   similar to database_name works.
  defp cachex_children() do
    [
      build_cachex("desu_login"),
      build_cachex("suestate")
    ]
  end

  defp build_cachex(type, opts \\ []) do
    %{
      id: String.to_atom("cachex_" <> type),
      start: {Cachex, :start_link, [String.to_atom(type <> "_cache"), opts]}
    }
  end
end
