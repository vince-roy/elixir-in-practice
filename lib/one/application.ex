defmodule One.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      OneWeb.Telemetry,
      # Start the Ecto repository
      One.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: One.PubSub},
      # Start Finch
      {Finch, name: One.Finch},
      # Start the Endpoint (http/https)
      OneWeb.Endpoint
      # Start a worker by calling: One.Worker.start_link(arg)
      # {One.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: One.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OneWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
