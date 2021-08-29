defmodule LeagueWeb.Presence do
  use Phoenix.Presence,
    otp_app: :league,
    pubsub_server: League.PubSub
end
