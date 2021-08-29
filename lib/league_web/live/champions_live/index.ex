defmodule LeagueWeb.ChampionsLive.Index do
  use LeagueWeb, :live_view

  alias League.{ExternalSites, Filters, Stats}

  @impl true
  def mount(_params, _session, socket) do
    champions = Stats.list_champions()

    {:ok,
     assign(socket,
       page_title: "League Champions",
       champions: champions,
       search_results: []
     )}
  end

  @impl true
  def handle_event("update_search", %{"search" => search}, socket) do
    search_results =
      if String.length(search) > 0 do
        socket.assigns.champions
        |> Enum.map(&{&1, Filters.fuzzy_match(search, &1.name)})
        |> Enum.sort_by(fn {_, {_, score}} -> score end, :desc)
        |> Enum.slice(0..10)
        |> Enum.filter(fn {_, {_, score}} -> score > 0 end)
      else
        []
      end

    {:noreply, assign(socket, :search_results, search_results)}
  end

  def highlight_matching_graphemes(string, matching_indexes) do
    String.graphemes(string)
    |> Enum.with_index()
    |> Enum.map(fn {grapheme, index} ->
      case grapheme do
        " " ->
          "<span>&nbsp;</span>"

        grapheme ->
          modifier = if Enum.member?(matching_indexes, index), do: "matched", else: "unmatched"
          ~s(<span class="search-results__letter--#{modifier}">#{grapheme}</span>)
      end
    end)
  end
end
