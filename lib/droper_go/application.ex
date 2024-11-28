defmodule DroperGo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DroperGo.Amazon.Order.OrderFetcher,
      DroperGoWeb.Telemetry,
      DroperGo.Repo,
      {DNSCluster, query: Application.get_env(:droper_go, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DroperGo.PubSub},
      # Start a worker by calling: DroperGo.Worker.start_link(arg)
      # {DroperGo.Worker, arg},
      # Start to serve requests, typically the last entry
      DroperGoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DroperGo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DroperGoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
