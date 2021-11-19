defmodule Subaru.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [Subaru.DB] ++ cachex_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Subaru.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp cachex_children() do
    [
      # cache extant {userid, chatid} occurrences. maximum 500 entries.
      build_cachex("user_chat_edges", limit: 500)
    ]
  end

  defp build_cachex(type, opts \\ []) do
    %{
      id: String.to_atom("cachex_" <> type),
      start: {Cachex, :start_link, [String.to_atom(type <> "_cache"), opts]},
      type: :worker
    }
  end
end
