defmodule League.Repo do
  use Ecto.Repo,
    otp_app: :league,
    adapter: Ecto.Adapters.Postgres
end
