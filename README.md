# league-stat-tracker

## To run

You will need an API key from [Riot](https://developer.riotgames.com/).
Once you've obtained an API key, set it as the value of the environment variable `RIOT_API_KEY`.

```bash
export RIOT_API_KEY="RGAPI-xyz"
```

where `RGAPI-xyz` is replaced with your full API key.

### Without Docker

Run:

#### `mix setup && mix phx.server`

This assumes you have the necessary Erlang, Elixir, and other requirements installed. A guide for
getting a Phoenix project up and running can be found on their [website](https://hexdocs.pm/phoenix/installation.html#content).

The app will run in development mode, served at http://localhost:4000. You will need a running
Postgres server available.

### With Docker + Docker-compose

Run:

#### `make build-prod && make run-prod`

The API will be served in production mode, served at http://localhost:4000. This will also create
a separate Postgres container to store the data.

Since this is in production mode, it will require a fair amount of secrets set as environment
variables (these are all example values):

```bash
export POSTGRES_DB="league"
export POSTGRES_USER="produser"
export POSTGRES_PASSWORD="prodpassword"

export DATABASE_URL="ecto://$POSTGRES_USER:$POSTGRES_PASSWORD@postgres/$POSTGRES_DB"

export SECRET_KEY_BASE="secretsecret"
export HOST="league.example.com"
export PORT=4000

export RIOT_API_KEY="RGAPI-xyz"
export DEFAULT_QUEUE="ranked_solo"
export DEFAULT_SUMMONER="Go ln With Me"
```

To run database migrations and seed data:

```bash
make migrate-prod
make seed-prod
```
