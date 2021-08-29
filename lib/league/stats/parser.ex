defmodule League.Stats.Parser do
  @moduledoc """
  Parser for API responses from the Riot API.
  """

  @doc """
  Parses match details for the given user.

  Stats from other participants in the match will be ignored.
  """
  def parse_match_stats(account_id, match_details) do
    participant_identity =
      Enum.find(
        match_details["participantIdentities"],
        &(&1["player"]["currentAccountId"] == account_id)
      )

    participant_id = participant_identity["participantId"]

    participant =
      Enum.find(match_details["participants"], &(&1["participantId"] == participant_id))

    stats = participant["stats"]
    role = parse_match_role(participant["timeline"]["lane"], participant["timeline"]["role"])
    items = parse_match_items(stats)

    %{
      id: match_details["gameId"],
      account_id: account_id,
      start_time: match_details["gameCreation"],
      duration: match_details["gameDuration"],
      game_version: match_details["gameVersion"],
      season_id: match_details["seasonId"],
      queue_id: match_details["queueId"],
      did_win: stats["win"],
      champion_id: participant["championId"],
      role: role,
      stats: %{
        "kills" => stats["kills"],
        "assists" => stats["assists"],
        "deaths" => stats["deaths"],
        "champion_damage" => stats["totalDamageDealtToChampions"],
        "damage_taken" => stats["totalDamageTaken"],
        "turret_damage" => stats["damageDealtToTurrets"],
        "gold_earned" => stats["goldEarned"],
        "cs" => stats["totalMinionsKilled"] + stats["neutralMinionsKilled"],
        "cs_per_min" => participant["timeline"]["creepsPerMinDeltas"],
        "cs_diff_per_min" => participant["timeline"]["csDiffPerMinDeltas"],
        "vision_score" => stats["visionScore"],
        "items" => items
      }
    }
  end

  defp parse_match_role(lane, role) do
    cond do
      lane in ["TOP", "MIDDLE", "JUNGLE"] -> String.downcase(lane)
      role == "DUO_CARRY" -> "bottom"
      role == "DUO_SUPPORT" -> "support"
      true -> nil
    end
  end

  defp parse_match_items(participant_stats) do
    for i <- 0..6 do
      item = participant_stats["item#{i}"]
      if item == 0, do: nil, else: item
    end
  end

  @doc """
  Parses match details for the given user.

  Stats from other participants in the match will be ignored.
  """
  def parse_ranked_tier(ranked_tier) do
    # TODO: Handle all queue types
    queue_id =
      case ranked_tier["queueType"] do
        "RANKED_SOLO_5x5" -> "ranked_solo"
        _ -> ranked_tier["queueType"]
      end

    %{
      "queue_id" => queue_id,
      "tier" => ranked_tier["tier"],
      "rank" => ranked_tier["rank"],
      "league_points" => ranked_tier["leaguePoints"],
      "wins" => ranked_tier["wins"],
      "losses" => ranked_tier["losses"],
      "win_percent" => ranked_tier["wins"] / (ranked_tier["wins"] + ranked_tier["losses"]),
      "promos" => ranked_tier["miniSeries"]["progress"]
    }
  end

  @doc """
  Parses all participants within a match.
  """
  def parse_match_participants(%{
        "participants" => participants,
        "participantIdentities" => identities
      }) do
    participants = Enum.sort_by(participants, & &1["participantId"])
    identities = Enum.sort_by(identities, & &1["participantId"])

    for {participant, identity} <- Enum.zip(participants, identities) do
      Map.merge(parse_participant(participant), parse_identity(identity))
    end
  end

  defp parse_participant(%{
         "participantId" => participant_id,
         "teamId" => team_id,
         "championId" => champion_id,
         "stats" => stats
       }) do
    %{
      participant_id: participant_id,
      team_id: team_id,
      champion_id: champion_id,
      kills: stats["kills"],
      deaths: stats["deaths"],
      assists: stats["assists"],
      cs: stats["totalMinionsKilled"] + stats["neutralMinionsKilled"],
      champion_damage: stats["totalDamageDealtToChampions"],
      gold_earned: stats["goldEarned"],
      items: parse_match_items(stats)
    }
  end

  defp parse_identity(%{"player" => player}) do
    %{
      name: player["summonerName"],
      account_id: player["currentAccountId"],
      summoner_id: player["summonerId"]
    }
  end
end
