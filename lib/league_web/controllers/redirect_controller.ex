defmodule LeagueWeb.RedirectController do
  use LeagueWeb, :controller

  alias League.Defaults

  def index(conn, _params) do
    redirect(conn,
      to:
        Routes.summary_index_path(
          conn,
          :index,
          Defaults.fetch_default_summoner!(),
          queue: Defaults.fetch_default_queue!()
        )
    )
  end
end
