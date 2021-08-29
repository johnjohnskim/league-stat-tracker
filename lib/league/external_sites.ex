defmodule League.ExternalSites do
  # The current League patch.
  @current_patch 11.16

  @moduledoc """
  Generates links to external sites.
  """

  @doc """
  Generates a URL for a champion icon.
  """
  def generate_champion_icon_url(key, patch \\ @current_patch),
    do: "#{get_base_icon_url(patch)}/champion/#{key}.png"

  @doc """
  Generates a URL for an item icon.
  """
  def generate_item_icon_url(id, patch \\ @current_patch),
    do: "#{get_base_icon_url(patch)}/item/#{Integer.to_string(id)}.png"

  defp get_base_icon_url(patch), do: "https://ddragon.leagueoflegends.com/cdn/#{patch}.1/img"

  @doc """
  Generates a URL to a champion page on mobalytics.gg.
  """
  def generate_mobalytics_url(champion_key) do
    "https://app.mobalytics.gg/lol/champions/#{String.downcase(champion_key)}/build"
  end

  @doc """
  Generates a URL to a champion page on poro.gg.
  """
  def generate_poro_url(champion_key) do
    "https://poro.gg/champions/#{String.downcase(champion_key)}"
  end

  @doc """
  Generates a URL to an ARAM champion page on u.gg.
  """
  def generate_ugg_url(champion_key) do
    cleaned_key =
      if champion_key == "MonkeyKing", do: "wukong", else: String.downcase(champion_key)

    "https://u.gg/lol/champions/aram/#{cleaned_key}-aram"
  end
end
