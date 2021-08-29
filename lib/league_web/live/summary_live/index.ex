defmodule LeagueWeb.SummaryLive.Index do
  use LeagueWeb, :live_view

  alias League.{Defaults, ExternalSites, PubSub, Stats}
  alias League.Stats.Summoner

  @queues %{
    "blind" => "Blind Pick",
    "draft" => "Draft Pick",
    "ranked_solo" => "Ranked Solo/Duo",
    "ranked_flex" => "Ranked Flex",
    "aram" => "ARAM"
  }
  @queue_types Map.keys(@queues)

  @table_fields [
    {"Champion", "champion_name"},
    {"Matches", "matches"},
    {"Win %", "win_percent"},
    {"KDA", "average_kda"},
    {"K", "average_kills"},
    {"D", "average_deaths"},
    {"A", "average_assists"},
    {"CS", "average_cs"},
    {"Given", "average_champion_damage"},
    {"Taken", "average_damage_taken"},
    {"Turret", "average_turret_damage"},
    {"Gold", "average_gold_earned"},
    {"Vision", "average_vision_score"}
  ]
  @sortable_fields Keyword.values(@table_fields)

  @impl true
  def mount(%{"summoner_name" => summoner_name}, _session, socket) do
    if connected?(socket) do
      subscribe(summoner_name)
      # TODO: Enable this once there's a better UI indicator that this is happening.
      # Process.send(self(), :update_stats, [])
    end

    summoner = Stats.find_summoner_by_name!(summoner_name)
    items = Stats.get_item_map()

    {:ok,
     assign(
       socket,
       page_title: "#{summoner.name} - Champion Stats",
       summoner: summoner,
       # TODO: Stop only showing ranked_solo stats?
       ranked_tier: summoner.ranked_tiers["ranked_solo"],
       queues: @queues,
       table_fields: @table_fields,
       sorted_by: {"matches", :desc},
       expanded_champions: %{},
       items: items
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    %{summoner: summoner, sorted_by: sorted_by} = socket.assigns

    queue =
      if params["queue"] in @queue_types,
        do: params["queue"],
        else: Defaults.fetch_default_queue!()

    champion_stats =
      summoner
      |> get_champion_stats(queue)
      |> sort_champion_stats(sorted_by)

    {:noreply, assign(socket, selected_queue: queue, champion_stats: champion_stats)}
  end

  @impl true
  def handle_event("select_queue", %{"queue" => queue}, socket) do
    {:noreply,
     push_patch(
       socket,
       # queue param validation is done downstream in handle_params.
       to: Routes.summary_index_path(socket, :index, socket.assigns.summoner.name, queue: queue),
       replace: true
     )}
  end

  @impl true
  def handle_event("update_stats", _value, socket) do
    socket = update_stats(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("sort_table", %{"sort_by" => sort_by}, socket)
      when sort_by in @sortable_fields do
    %{champion_stats: champion_stats, sorted_by: previous_sorted_by} = socket.assigns

    sorted_by =
      case previous_sorted_by do
        {^sort_by, :desc} -> {sort_by, :asc}
        _ -> {sort_by, :desc}
      end

    {:noreply,
     assign(socket,
       sorted_by: sorted_by,
       champion_stats: sort_champion_stats(champion_stats, sorted_by)
     )}
  end

  @impl true
  def handle_event("sort_table", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("expand_champion", %{"champion_id" => champion_id}, socket) do
    {:noreply,
     update(
       socket,
       :expanded_champions,
       fn expanded_champions ->
         Map.update(expanded_champions, String.to_integer(champion_id), true, &(!&1))
       end
     )}
  end

  @impl true
  def handle_info(:update_stats, socket) do
    socket = update_stats(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:stats_updated, %{queue: queue, champion_stats: champion_stats}}, socket) do
    socket =
      if queue == socket.assigns.selected_queue do
        assign(
          socket,
          :champion_stats,
          sort_champion_stats(champion_stats, socket.assigns.sorted_by)
        )
      else
        socket
      end

    {:noreply, socket}
  end

  defp subscribe(summoner_name) do
    Phoenix.PubSub.subscribe(PubSub, "champion_stats:#{summoner_name}")
  end

  defp broadcast(summoner_name, queue, champion_stats) do
    Phoenix.PubSub.broadcast(
      PubSub,
      "champion_stats:#{summoner_name}",
      {:stats_updated, %{queue: queue, champion_stats: champion_stats}}
    )
  end

  defp get_champion_stats(summoner, queue) do
    Stats.list_champion_stats(summoner, String.to_atom(queue))
  end

  defp sort_champion_stats(champion_stats, sorted_by) do
    {sort_key, sort_direction} = sorted_by

    mapper =
      case sort_key do
        "champion_name" ->
          & &1.champion.name

        "win_percent" ->
          fn champion_stat ->
            win_percent = champion_stat.stats["win_percent"]

            # If the win percents are equal, more matches played indicates a better win rate if
            # you're above a 50% win rate. The reverse is true for win rates below 50%.
            matches =
              if win_percent > 0.5,
                do: champion_stat.stats["matches"],
                else: -champion_stat.stats["matches"]

            {win_percent, matches}
          end

        _ ->
          & &1.stats[sort_key]
      end

    Enum.sort_by(champion_stats, mapper, sort_direction)
  end

  defp update_stats(socket) do
    %{summoner: summoner, selected_queue: queue, sorted_by: sorted_by} = socket.assigns

    socket =
      if Stats.update_matches(summoner, String.to_atom(queue)) do
        Stats.update_champion_stats(summoner, String.to_atom(queue))
        champion_stats = get_champion_stats(summoner, queue)
        broadcast(summoner.name, queue, champion_stats)

        assign(
          socket,
          :champion_stats,
          sort_champion_stats(champion_stats, sorted_by)
        )
      else
        socket
      end

    %Summoner{ranked_tiers: ranked_tiers} = Stats.update_ranked_tiers(summoner)
    assign(socket, :ranked_tier, ranked_tiers["ranked_solo"])
  end

  def format_percent(percent) do
    "#{Float.round(percent * 100, 2)}%"
  end

  def get_percent_class_mod(percent) do
    if percent >= 0.5, do: "--pos", else: "--neg"
  end

  def add_sort_arrow(sorted_by, attribute) do
    case sorted_by do
      {^attribute, :asc} -> "↑"
      {^attribute, :desc} -> "↓"
      _ -> nil
    end
  end

  def get_promo_class_mod(promo) do
    case promo do
      "W" -> "win"
      "L" -> "loss"
      "N" -> "none"
    end
  end
end
