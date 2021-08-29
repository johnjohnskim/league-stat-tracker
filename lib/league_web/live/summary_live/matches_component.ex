defmodule LeagueWeb.SummaryLive.MatchesComponent do
  use Phoenix.LiveComponent

  alias League.{ExternalSites, Stats, TimeFormatters}
  alias LeagueWeb.Router.Helpers, as: Routes

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{summoner: summoner, id: champion_id, queue: queue, items: items}, socket) do
    champion = Stats.get_champion_by_id!(champion_id)

    # We're loading the matches here instead of preload/1, since we'll rarely want to load
    # matches for more than one or two champs.
    matches =
      summoner
      |> Stats.list_matches(champion, String.to_atom(queue))
      |> Enum.sort_by(& &1.start_time, :desc)
      |> Enum.map(&prettify_match_details(&1, items))

    {:ok, assign(socket, matches: matches)}
  end

  defp prettify_match_details(match, items) do
    [major | [minor | _]] = String.split(match.game_version, ".")

    stats =
      Map.update!(match.stats, "items", fn item_ids ->
        for item_id <- item_ids do
          if item_id, do: items[item_id], else: nil
        end
      end)

    struct(match, %{
      game_version: "#{major}.#{minor}",
      start_time: TimeFormatters.format_datetime(match.start_time),
      duration: TimeFormatters.format_duration(match.duration),
      stats: stats
    })
  end
end
