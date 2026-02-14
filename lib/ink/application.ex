defmodule Ink.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      InkWeb.Telemetry,
      Ink.Repo,
      {DNSCluster, query: Application.get_env(:ink, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Ink.PubSub},
      # Start a worker by calling: Ink.Worker.start_link(arg)
      # {Ink.Worker, arg},
      # Start to serve requests, typically the last entry
      InkWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ink.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    InkWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
