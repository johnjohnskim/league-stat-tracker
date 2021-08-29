defmodule LeagueWeb.MatchLive.TeamChartComponent do
  use Phoenix.LiveComponent

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{timestamps: timestamps, gold: gold, exp: exp}, socket) do
    {:ok, assign(socket, gold: Enum.zip(timestamps, gold), exp: Enum.zip(timestamps, exp))}
  end
end
