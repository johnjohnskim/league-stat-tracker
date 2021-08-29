defmodule LeagueWeb.MatchLive.PlayerChartComponent do
  use Phoenix.LiveComponent

  alias League.ExternalSites

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{participants: participants, timestamps: timestamps, data: data}, socket) do
    participant_helper_map = Map.new(participants, &{&1.participant_id, {&1.champion, &1.winner}})

    data =
      for {id, values} <- data do
        {champion, winner} = participant_helper_map[id]
        {id, champion, winner, Enum.zip(timestamps, values)}
      end

    {:ok, assign(socket, :data, data)}
  end
end
