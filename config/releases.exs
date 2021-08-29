# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :league, League.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

host =
  System.get_env("HOST") ||
    raise """
    environment variable HOST is missing.
    """

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :league, LeagueWeb.Endpoint,
  url: [host: host, port: 80],
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

riot_api_key =
  System.get_env("RIOT_API_KEY") ||
    raise """
    environment variable RIOT_API_KEY is missing.
    """

# Configures the Riot API key, default queue, and summoner
config :league,
  riot_api_key: System.get_env("RIOT_API_KEY"),
  default_queue: System.get_env("DEFAULT_QUEUE") || "ranked_solo",
  default_summoner: System.get_env("DEFAULT_SUMMONER") || "Go ln With Me"

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
config :league, LeagueWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
