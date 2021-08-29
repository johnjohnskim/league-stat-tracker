defmodule LeagueWeb.ARAMLive.Index do
  use LeagueWeb, :live_view

  alias League.{ExternalSites, PubSub, Tags}
  alias LeagueWeb.{Endpoint, Presence}
  alias Phoenix.Socket.Broadcast

  @default_rolls 2

  @impl true
  def mount(params, _session, socket) do
    id = params["id"] || generate_random_string()

    if connected?(socket) do
      subscribe(id)
      send(self(), :after_join)
    end

    mid_champions = Tags.get_mid_champions()
    top_champions = Tags.get_top_champions()

    {:ok,
     assign(socket,
       id: id,
       page_title: "ARAM (#{id})",
       mid_champions: mid_champions,
       top_champions: top_champions,
       player_champions: reroll_champions(mid_champions, top_champions),
       player_rolls: reset_rolls(),
       player_colors: %{"1" => "blue", "2" => "red"},
       default_rolls: @default_rolls,
       connected: false
     )}
  end

  @impl true
  def handle_info(:after_join, socket) do
    room = get_room_from_socket(socket)
    online_players = Presence.list(room)

    player =
      cond do
        not Map.has_key?(online_players, "1") -> "1"
        not Map.has_key?(online_players, "2") -> "2"
        true -> "3"
      end

    Presence.track(self(), room, player, %{})

    # Reset the champ select and rolls every time a player joins.
    %{id: id, player_champions: player_champions, player_rolls: player_rolls} = socket.assigns
    broadcast(id, player_champions, player_rolls)

    {:noreply,
     assign(socket,
       current_player: player,
       online_players: online_players,
       connected: true
     )}
  end

  @impl true
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :online_players, Presence.list(get_room_from_socket(socket)))}
  end

  @impl true
  def handle_info(
        {:rerolled, %{player_champions: player_champions, player_rolls: player_rolls}},
        socket
      ) do
    {:noreply, assign(socket, player_champions: player_champions, player_rolls: player_rolls)}
  end

  @impl true
  def handle_event("reroll", _value, socket) do
    %{
      id: id,
      mid_champions: mid_champions,
      top_champions: top_champions,
      current_player: player,
      player_rolls: player_rolls
    } = socket.assigns

    # TODO: Prevent rolls if the player has 0 rolls left (this is currently handled in the UI).
    player_champions = reroll_champions(mid_champions, top_champions)
    player_rolls = Map.update(player_rolls, player, @default_rolls - 1, &(&1 - 1))

    broadcast(id, player_champions, player_rolls)

    {:noreply, assign(socket, player_champions: player_champions, player_rolls: player_rolls)}
  end

  @impl true
  def handle_event("reset", _value, socket) do
    %{id: id, mid_champions: mid_champions, top_champions: top_champions} = socket.assigns

    player_champions = reroll_champions(mid_champions, top_champions)
    player_rolls = reset_rolls()

    broadcast(id, player_champions, player_rolls)

    {:noreply, assign(socket, player_champions: player_champions, player_rolls: player_rolls)}
  end

  defp subscribe(id) do
    Phoenix.PubSub.subscribe(PubSub, get_room(id))
  end

  defp broadcast(id, player_champions, player_rolls) do
    Phoenix.PubSub.broadcast(
      PubSub,
      get_room(id),
      {:rerolled, %{player_champions: player_champions, player_rolls: player_rolls}}
    )
  end

  defp get_room_from_socket(socket) do
    get_room(socket.assigns[:id])
  end

  defp get_room(id) do
    "aram:#{id}"
  end

  defp reroll_champions(mid_champions, top_champions) do
    champions =
      case Enum.random([:mid, :top]) do
        :mid -> mid_champions
        :top -> top_champions
      end

    %{"1" => Enum.random(champions), "2" => Enum.random(champions)}
  end

  defp reset_rolls() do
    %{"1" => @default_rolls, "2" => @default_rolls}
  end

  defp generate_random_string(length \\ 12) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
