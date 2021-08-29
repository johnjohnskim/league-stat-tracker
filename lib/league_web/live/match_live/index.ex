defmodule LeagueWeb.MatchLive.Index do
  use LeagueWeb, :live_view

  alias League.{Stats, TimeFormatters}

  @impl true
  def mount(%{"match_id" => match_id}, _session, socket) do
    match =
      case Stats.get_match_breakdown(match_id) do
        {:error, :not_found} ->
          nil

        {:ok, match} ->
          match
          |> prettify_match_details()
          |> Map.update!(
            :participants,
            &setup_participants(
              &1,
              match.duration,
              match.winning_team,
              Stats.get_champion_map(),
              Stats.get_item_map()
            )
          )
      end

    red_team = Enum.filter(match[:participants] || [], &(&1.team_id == 100))
    blue_team = Enum.filter(match[:participants] || [], &(&1.team_id == 200))

    red_team_class =
      if match[:winning_team] == 100,
        do: "match__team-name--winner",
        else: "match__team-name--loser"

    blue_team_class =
      if match[:winning_team] == 200,
        do: "match__team-name--winner",
        else: "match__team-name--loser"

    {:ok,
     assign(socket,
       page_title: "Match #{match_id}",
       tabs: [:scoreboard, :charts],
       selected_tab: :scoreboard,
       chart_tabs: [
         {:teams, "Team XP and Net Worth"},
         {:gold, "Player Net Worth"},
         {:exp, "Player XP"}
       ],
       selected_chart_tab: :teams,
       match: match,
       red_team: red_team,
       blue_team: blue_team,
       red_team_class: red_team_class,
       blue_team_class: blue_team_class
     )}
  end

  @impl true
  def handle_event("switch_to_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :selected_tab, String.to_atom(tab))}
  end

  @impl true
  def handle_event("switch_to_chart_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :selected_chart_tab, String.to_atom(tab))}
  end

  defp prettify_match_details(match) do
    match
    |> Map.update!(:game_version, fn game_version ->
      [major | [minor | _]] = String.split(game_version, ".")
      "#{major}.#{minor}"
    end)
    |> Map.update!(:start_time, &TimeFormatters.format_datetime/1)
    |> Map.update!(:duration, &TimeFormatters.format_duration/1)
  end

  defp setup_participants(participants, duration, winning_team, champion_map, item_map) do
    participant_to_champion_map =
      Map.new(participants, &{&1.participant_id, champion_map[&1.champion_id]})

    duration_minutes = duration / 60

    for participant <- participants do
      participant
      |> Map.put(:winner, participant.team_id == winning_team)
      |> Map.put(:cs_per_min, participant.cs / duration_minutes)
      |> Map.put(:champion_damage_per_min, participant.champion_damage / duration_minutes)
      |> Map.put(:gold_earned_per_min, participant.gold_earned / duration_minutes)
      |> Map.put(
        :kda,
        (participant.kills + participant.assists) / max(participant.deaths, 1)
      )
      |> Map.put(:champion, champion_map[participant.champion_id])
      |> Map.update!(:items, fn item_ids ->
        for item_id <- item_ids do
          if item_id, do: item_map[item_id], else: nil
        end
      end)
      |> Map.update!(:kill_breakdown, fn kill_breakdown ->
        kill_breakdown =
          for {participant_id, kills} <- kill_breakdown do
            %{
              champion: participant_to_champion_map[participant_id],
              participant_id: participant_id,
              kills: kills
            }
          end

        Enum.sort_by(kill_breakdown, & &1.participant_id)
      end)
    end
  end
end
