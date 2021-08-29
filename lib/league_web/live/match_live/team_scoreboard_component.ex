defmodule LeagueWeb.MatchLive.TeamScoreboardComponent do
  use Phoenix.LiveComponent

  alias League.ExternalSites

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{participants: participants}, socket) do
    {:ok, assign(socket, :participants, participants)}
  end
end
