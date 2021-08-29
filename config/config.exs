# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :league,
  ecto_repos: [League.Repo]

# Configures the endpoint
config :league, LeagueWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "KNO1Wj6T8ZBBcCa26okJLqIDnn3rMneSfsXQFfLOLES4G2dAh3tx21c1CsNlwH5/",
  render_errors: [view: LeagueWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: League.PubSub,
  live_view: [signing_salt: "D4ci8XKTW/dZ66jSEqD1b00R7lSGpAPq"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
