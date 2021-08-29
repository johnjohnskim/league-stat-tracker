defmodule League.Stats do
  @moduledoc """
  Fetch, aggregate and store League match stats.
  """

  require Logger
  require Ecto.Query
  import Ecto.Query
  alias League.{Repo, API}
  alias League.Stats.{Summoner, Champion, Item, Match, ChampionStat, Parser}

  # The only season we're currently tracking.
  @current_season 11

  @doc """
  Gets the summoner by their summoner name.

  If the summoner is not found, it will be fetched from the Riot API and stored.
  """
  def find_summoner_by_name!(summoner_name) do
    case Repo.get_by(Summoner, name: summoner_name) do
      %Summoner{} = summoner ->
        summoner

      nil ->
        {:ok, %{"puuid" => puuid, "name" => name, "id" => summoner_id, "accountId" => account_id}} =
          API.get_summoner(name: summoner_name)

        %Summoner{}
        |> Summoner.changeset(%{
          puuid: puuid,
          name: name,
          summoner_id: summoner_id,
          account_id: account_id
        })
        |> Repo.insert!()
    end
  end

  @doc """
  Gets the summoner by their PUUID.
  """
  def get_summoner_by_puuid!(puuid), do: Repo.get!(Summoner, puuid)

  @doc """
  Returns the list of champions.
  """
  def list_champions, do: Repo.all(Champion)

  @doc """
  Returns a map of champions: %{champion_id => champion}.
  """
  def get_champion_map do
    from(c in Champion, select: {c.id, c})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Get the champion by their name.
  """
  def get_champion_by_name!(champion_name), do: Repo.get_by!(Champion, name: champion_name)

  @doc """
  Get the champion by their ID.
  """
  def get_champion_by_id!(champion_id), do: Repo.get!(Champion, champion_id)

  @doc """
  Returns the list of items.
  """
  def list_items, do: Repo.all(Item)

  @doc """
  Returns a map of items: %{item_id => item}.
  """
  def get_item_map do
    from(i in Item, select: {i.id, i})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Returns the list of matches for the given summoner, champion, and queue.
  """
  def list_matches(%Summoner{} = summoner, %Champion{} = champion, queue) do
    Match
    |> where(
      summoner_puuid: ^summoner.puuid,
      champion_id: ^champion.id,
      queue_id: ^API.get_queue_id(queue)
    )
    |> Repo.all()
    |> Enum.map(&calculate_derived_match_stats/1)
  end

  defp calculate_derived_match_stats(%Match{} = match) do
    stats = match.stats

    derived_stats = %{
      # Ensure a non-zero denominator.
      "kda" => (stats["kills"] + stats["assists"]) / max(stats["deaths"], 1)
    }

    per_min_stats =
      for stat <- [
            "cs",
            "champion_damage",
            "damage_taken",
            "turret_damage",
            "gold_earned",
            "vision_score"
          ],
          into: %{},
          do: {"per_min_#{stat}", stats[stat] / (match.duration / 60)}

    derived_stats = Map.merge(derived_stats, per_min_stats)
    %{match | stats: Map.merge(stats, derived_stats)}
  end

  @doc """
  Returns the list of aggregated champion stats for the given summoner and queue.
  """
  def list_champion_stats(%Summoner{} = summoner, queue) do
    ChampionStat
    |> where(summoner_puuid: ^summoner.puuid, queue_id: ^API.get_queue_id(queue))
    |> Repo.all()
    |> Repo.preload(:champion)
    |> Enum.map(&calculate_derived_champion_stats/1)
  end

  defp calculate_derived_champion_stats(%ChampionStat{} = champion_stats) do
    stats = champion_stats.stats

    derived_stats = %{
      "losses" => stats["matches"] - stats["wins"],
      "win_percent" => stats["wins"] / stats["matches"],
      # Ensure a non-zero denominator.
      "average_kda" => (stats["kills"] + stats["assists"]) / max(stats["deaths"], 1)
    }

    averaged_stats =
      for stat <- [
            "kills",
            "deaths",
            "assists",
            "cs",
            "champion_damage",
            "damage_taken",
            "turret_damage",
            "gold_earned",
            "vision_score"
          ],
          into: %{},
          do: {"average_#{stat}", stats[stat] / stats["matches"]}

    derived_stats = Map.merge(derived_stats, averaged_stats)
    %{champion_stats | stats: Map.merge(stats, derived_stats)}
  end

  @doc """
  Updates the stored ranked info for the given summoner.
  """
  def update_ranked_tiers(%Summoner{} = summoner) do
    {:ok, response} = API.get_ranked_stats(summoner.summoner_id)

    ranked_tiers =
      response
      |> Enum.map(&Parser.parse_ranked_tier/1)
      |> Map.new(&{&1["queue_id"], &1})

    summoner
    |> Summoner.changeset(%{ranked_tiers: ranked_tiers})
    |> Repo.update!()
  end

  @doc """
  Updates the stored matches for the given summoner and queue.
  """
  def update_matches(%Summoner{} = summoner, queue) do
    queue_id = API.get_queue_id(queue)

    last_start_time =
      Repo.one(
        from(m in Match,
          where: m.summoner_puuid == ^summoner.puuid and m.queue_id == ^queue_id,
          select: max(m.start_time)
        )
      )

    {min_start_time, _} = API.get_season_timestamps(@current_season)
    last_start_time = if last_start_time, do: last_start_time + 1, else: min_start_time

    response =
      API.get_full_matchlist(
        summoner.account_id,
        # season: @season,
        queue: queue,
        begin_time: last_start_time
      )

    case response do
      {:ok, matchlist} ->
        Logger.info("saving #{Enum.count(matchlist)} matches")

        matchlist
        |> Enum.sort_by(& &1["gameId"])
        |> Stream.map(&fetch_match(&1["gameId"]))
        |> Stream.filter(&good_match?/1)
        |> Stream.map(&Parser.parse_match_stats(summoner.account_id, &1))
        |> Stream.map(&Map.put(&1, :summoner_puuid, summoner.puuid))
        |> Stream.map(&Match.changeset(%Match{}, &1))
        |> Enum.map(&Repo.insert!/1)

      {:error, :not_found} ->
        Logger.info("no matches found")
        nil
    end
  end

  defp good_match?(match), do: match["gameDuration"] > 300

  defp fetch_match(match_id) do
    # Ensure we don't hit the Riot API rate limit.
    :timer.sleep(1300)
    Logger.info("fetching match #{match_id}")
    {:ok, match} = API.get_match(match_id)
    match
  end

  @doc """
  Updates the aggregated champion stats for the given summoner and queue.
  """
  def update_champion_stats(%Summoner{} = summoner, queue) do
    queue_id = API.get_queue_id(queue)
    last_updated = summoner.last_updated_timestamps[Integer.to_string(queue_id)] || 0

    matches =
      Match
      |> where(summoner_puuid: ^summoner.puuid, queue_id: ^queue_id)
      |> where([m], m.start_time > ^last_updated)
      |> Repo.all()

    if Enum.any?(matches) do
      Logger.info("rolling up #{Enum.count(matches)} matches")

      champion_stats =
        matches
        |> rollup_match_stats()
        |> Enum.map(&store_champion_stats(summoner.puuid, queue_id, &1))

      max_start_time = matches |> Enum.map(& &1.start_time) |> Enum.max()

      new_last_updated =
        Map.put(
          summoner.last_updated_timestamps || %{},
          Integer.to_string(queue_id),
          max_start_time
        )

      summoner
      |> Summoner.changeset(%{last_updated_timestamps: new_last_updated})
      |> Repo.update!()

      champion_stats
    else
      Logger.info("no matches found")
      nil
    end
  end

  defp rollup_match_stats(matches) do
    sum_keys = ["kills", "assists", "deaths"]

    per_min_keys = [
      "champion_damage",
      "damage_taken",
      "turret_damage",
      "gold_earned",
      "vision_score",
      "cs"
    ]

    grouped_matches = Enum.group_by(matches, & &1.champion_id)

    for {champion_id, matches} <- grouped_matches do
      Enum.reduce(matches, %{"champion_id" => champion_id}, fn match, acc ->
        win_val = if match.did_win, do: 1, else: 0

        acc =
          acc
          |> Map.update("matches", 1, &(&1 + 1))
          |> Map.update("wins", win_val, &(&1 + win_val))
          |> Map.update("duration", match.duration, &(&1 + match.duration))

        acc =
          Enum.reduce(sum_keys, acc, fn key, sub_acc ->
            Map.update(sub_acc, key, match.stats[key], &(&1 + match.stats[key]))
          end)

        duration_minutes = match.duration / 60

        Enum.reduce(per_min_keys, acc, fn key, sub_acc ->
          Map.update(
            sub_acc,
            key,
            match.stats[key] / duration_minutes,
            &(&1 + match.stats[key] / duration_minutes)
          )
        end)
      end)
    end
  end

  defp store_champion_stats(summoner_puuid, queue_id, champion_stats) do
    {champion_id, champion_stats} = Map.pop(champion_stats, "champion_id")

    existing_champion_stats =
      ChampionStat
      |> where(
        summoner_puuid: ^summoner_puuid,
        queue_id: ^queue_id,
        champion_id: ^champion_id
      )
      |> Repo.one()

    if existing_champion_stats do
      new_stats =
        Map.merge(champion_stats, existing_champion_stats.stats, fn _key, v1, v2 ->
          v1 + v2
        end)

      existing_champion_stats
      |> ChampionStat.changeset(%{stats: new_stats})
      |> Repo.update!()
    else
      %ChampionStat{}
      |> ChampionStat.changeset(%{
        summoner_puuid: summoner_puuid,
        champion_id: champion_id,
        queue_id: queue_id,
        stats: champion_stats
      })
      |> Repo.insert!()
    end
  end

  @doc """
  Gets a breakdown of a match. This includes the participants, their current solo queue ranks, and
  how many times they killed players on the enemy team.
  """
  def get_match_breakdown(match_id) do
    case API.get_match(match_id) do
      {:error, :not_found} = error ->
        error

      {:ok, match} ->
        participants = Parser.parse_match_participants(match)

        {:ok, match_timeline} = API.get_match_timeline(match_id)
        kill_breakdowns = get_kill_breakdowns(match_timeline)

        {
          timestamps,
          team_gold_diff_timeline,
          team_exp_diff_timeline,
          participant_gold_timelines,
          participant_exp_timelines
        } = get_timelines(match_timeline)

        solo_queue_ranks =
          participants
          |> Enum.map(& &1.summoner_id)
          |> get_participants_ranked_stats()
          |> Enum.map(&find_participant_solo_queue_rank/1)

        match_breakdown = %{
          start_time: match["gameCreation"],
          duration: match["gameDuration"],
          game_mode: match["gameMode"],
          game_version: match["gameVersion"],
          winning_team:
            case hd(match["teams"])["win"] do
              "Win" -> 100
              "Fail" -> 200
            end,
          participants:
            for {participant, kill_breakdown, solo_queue_rank} <-
                  Enum.zip([participants, kill_breakdowns, solo_queue_ranks]) do
              participant
              |> Map.put(:kill_breakdown, kill_breakdown)
              |> Map.put(:solo_queue, solo_queue_rank)
            end,
          timelines: %{
            timestamps: timestamps,
            team_gold_diff: team_gold_diff_timeline,
            team_exp_diff: team_exp_diff_timeline,
            participants_gold: participant_gold_timelines,
            participants_exp: participant_exp_timelines
          }
        }

        {:ok, match_breakdown}
    end
  end

  defp get_kill_breakdowns(%{"frames" => frames}) do
    # NOTE: I'm not too sure what a "killerId" of 0 means in this context. It should denote tower
    #   kills, but those are usually classified as a different event type.
    kill_events =
      for frame <- frames,
          event <- frame["events"],
          event["type"] == "CHAMPION_KILL" && event["killerId"] != 0,
          do: event

    participants =
      for i <- 1..10,
          into: %{} do
        participant =
          if i < 6 do
            Map.new(6..10, &{&1, 0})
          else
            Map.new(1..5, &{&1, 0})
          end

        {i, participant}
      end

    participants =
      Enum.reduce(kill_events, participants, fn event, acc ->
        update_in(acc[event["killerId"]][event["victimId"]], &(&1 + 1))
      end)

    participants
    |> Enum.sort_by(fn {id, _} -> id end)
    |> Enum.map(fn {_, participant} -> participant end)
  end

  defp get_timelines(%{"frames" => frames}) do
    empty_participant_map = for i <- 1..10, into: %{}, do: {i, []}

    frames
    |> Enum.reverse()
    |> Enum.reduce(
      {
        [],
        [],
        [],
        empty_participant_map,
        empty_participant_map
      },
      fn frame,
         {
           timestamps,
           team_gold_diff_timeline,
           team_exp_diff_timeline,
           participant_gold_timelines,
           participant_exp_timelines
         } ->
        participants =
          for {_, participant} <- frame["participantFrames"] do
            {participant["participantId"], participant["totalGold"], participant["xp"]}
          end

        {team_gold_diff, team_exp_diff} =
          Enum.reduce(participants, {0, 0}, fn {id, gold, exp}, {team_gold_diff, team_exp_diff} ->
            if id <= 5 do
              {team_gold_diff + gold, team_exp_diff + exp}
            else
              {team_gold_diff - gold, team_exp_diff - exp}
            end
          end)

        timestamps = [frame["timestamp"] | timestamps]
        team_gold_diff_timeline = [team_gold_diff | team_gold_diff_timeline]
        team_exp_diff_timeline = [team_exp_diff | team_exp_diff_timeline]

        participant_gold_timelines =
          Enum.reduce(participants, participant_gold_timelines, fn {id, gold, _}, acc ->
            Map.update!(acc, id, fn timeline -> [gold | timeline] end)
          end)

        participant_exp_timelines =
          Enum.reduce(participants, participant_exp_timelines, fn {id, _, exp}, acc ->
            Map.update!(acc, id, fn timeline -> [exp | timeline] end)
          end)

        {
          timestamps,
          team_gold_diff_timeline,
          team_exp_diff_timeline,
          participant_gold_timelines,
          participant_exp_timelines
        }
      end
    )
  end

  defp get_participants_ranked_stats(summoner_ids) do
    summoner_ids
    |> Enum.map(&Task.async(fn -> API.get_ranked_stats(&1) end))
    |> Enum.map(&Task.await/1)
    |> Enum.map(fn {:ok, ranked_stats} -> ranked_stats end)
  end

  defp find_participant_solo_queue_rank(ranked_stats) do
    case Enum.find(ranked_stats, &(&1["queueType"] == "RANKED_SOLO_5x5")) do
      nil ->
        nil

      solo_queue_stats ->
        %{tier: solo_queue_stats["tier"], rank: solo_queue_stats["rank"]}
    end
  end
end
