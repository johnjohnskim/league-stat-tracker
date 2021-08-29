defmodule LeagueWeb.Router do
  use LeagueWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LeagueWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LeagueWeb do
    pipe_through :browser

    get "/", RedirectController, :index
    get "/summary", RedirectController, :index
    live "/summary/:summoner_name", SummaryLive.Index, :index
    live "/champions", ChampionsLive.Index, :index
    live "/match/:match_id", MatchLive.Index, :index
    live "/aram", ARAMLive.Index, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", LeagueWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: LeagueWeb.Telemetry
    end
  end
end
