defmodule SueWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SueWeb.Telemetry,
      # Start the Endpoint (http/https)
      SueWeb.Endpoint
      # Start a worker by calling: SueWeb.Worker.start_link(arg)
      # {SueWeb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SueWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SueWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
