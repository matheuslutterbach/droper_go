# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :droper_go,
  ecto_repos: [DroperGo.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :droper_go, DroperGoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: DroperGoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: DroperGo.PubSub,
  live_view: [signing_salt: "mIXd3/EF"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :your_app,
  amazon_refresh_token: System.get_env("AMAZON_REFRESH_TOKEN"),
  amazon_client_id: System.get_env("AMAZON_CLIENT_ID"),
  amazon_client_secret: System.get_env("AMAZON_CLIENT_SECRET"),
  amazon_marketplace_id: System.get_env("AMAZON_MARKETPLACE_ID")
