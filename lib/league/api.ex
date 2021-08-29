defmodule League.API do
  @moduledoc """
  Wrapper for the League of Legends / Riot API.
  """

  # TODO: Make the region dynamic/configurable
  @base_url "https://na1.api.riotgames.com/lol/"
  @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " <>
                "(KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"

  # League season => Unix timestamps for the start and end of that season.
  @seasons %{
    # 7 => {1_484_121_600_000, 1_515_571_199_000},
    # 8 => {1_515_571_200_000, 1_547_020_799_000},
    # 9 => {1_547_020_800_000, 1_578_477_599_000},
    # 10 => {1_578_477_600_000, 1_609_919_999_000},
    11 => {1_609_920_000_000, nil}
  }
  # Queue IDs for the different queues and game modes => Riot ID.
  @queues %{
    blind: 430,
    draft: 400,
    ranked_solo: 420,
    ranked_flex: 440,
    aram: 450
  }

  @doc """
  Makes a request to the Riot API.
  """
  def request(path, opts \\ []) do
    case fetch_api_key!() do
      nil -> {:error, :no_api_key}
      api_key -> do_request(api_key, path, 2, opts)
    end
  end

  defp do_request(api_key, path, tries, opts)
  defp do_request(_api_key, _path, 0, _opts), do: {:error, :timeout}

  defp do_request(api_key, path, tries, opts) do
    url = @base_url <> path
    headers = [{"X-Riot-Token", api_key}, {"User-Agent", @user_agent}]

    case HTTPoison.get(url, headers, params: opts[:params]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code}} when status_code in [429, 503, 504] ->
        :timer.sleep(500)
        do_request(api_key, path, tries - 1, opts)

      {:ok, %HTTPoison.Response{status_code: 403}} ->
        {:error, :forbidden}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}
    end
  end

  defp fetch_api_key! do
    Application.fetch_env!(:league, :riot_api_key)
  end

  @doc """
  Gets the summoner by their summoner name.
  """
  def get_summoner(params \\ []) do
    path_part =
      cond do
        params[:puuid] ->
          "by-puuid/#{params[:puuid]}"

        params[:name] ->
          "by-name/#{params[:name]}"

        params[:summoner_id] ->
          params[:summoner_id]

        params[:account_id] ->
          "by-account/#{params[:account_id]}"

        true ->
          raise ArgumentError, "one of :puuid, :name, :summoner_id, or :account_id must be given"
      end

    request("summoner/v4/summoners/#{path_part}")
  end

  @doc """
  Gets the ranked stats / info for the given summoner.
  """
  def get_ranked_stats(summoner_id),
    do: request("league/v4/entries/by-summoner/#{summoner_id}")

  @doc """
  Gets the champion masteries for the given summoner.
  """
  def get_champion_masteries(summoner_id),
    do: request("champion-mastery/v4/champion-masteries/by-summoner/#{summoner_id}")

  @doc """
  Gets a matchlist for the given summoner.

  May return a partial list, depending on the number of total matches you're attempting
  to fetch.
  """
  def get_matchlist(account_id, params \\ []) do
    cleaned_params = %{
      # "season" => params[:season], # Deprecated parameter
      "queue" => params[:queue],
      "beginTime" => params[:begin_time],
      "endTime" => params[:end_time],
      "beginIndex" => params[:begin_index],
      "endIndex" => params[:end_index]
    }

    request("match/v4/matchlists/by-account/#{account_id}", params: cleaned_params)
  end

  @doc """
  Gets a full matchlist for the given summoner.

  Handles using "endIndex" to continually fetch the rest of the matches.
  """
  def get_full_matchlist(account_id, opts \\ []) do
    case do_get_full_matchlist(account_id, 0, nil, [], opts) do
      matchlist when is_list(matchlist) -> {:ok, matchlist}
      {:error, _} = error -> error
    end
  end

  defp do_get_full_matchlist(_account_id, begin_index, total_games, matches, _opts)
       when begin_index >= total_games do
    matches
  end

  defp do_get_full_matchlist(account_id, begin_index, _total_games, matches, opts) do
    response =
      get_matchlist(
        account_id,
        season: @seasons[opts[:season]],
        queue: @queues[opts[:queue]],
        begin_time: opts[:begin_time],
        end_time: opts[:end_time],
        begin_index: begin_index
      )

    case response do
      {:ok, data} ->
        do_get_full_matchlist(
          account_id,
          data["endIndex"],
          data["totalGames"],
          data["matches"] ++ matches,
          opts
        )

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets details for a single match.
  """
  def get_match(match_id),
    do: request("match/v4/matches/#{match_id}")

  @doc """
  Gets a timeline for a specific match.
  """
  def get_match_timeline(match_id),
    do: request("match/v4/timelines/by-match/#{match_id}")

  @doc """
  Gets the season start and end dates for the given League season.
  """
  def get_season_timestamps(season), do: @seasons[season]

  @doc """
  Gets the Riot ID for the given queue.
  """
  def get_queue_id(queue), do: @queues[queue]
end
