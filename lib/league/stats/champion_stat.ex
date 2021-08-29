defmodule League.Stats.ChampionStat do
  use Ecto.Schema
  import Ecto.Changeset
  alias League.Stats.{Summoner, Champion}

  schema "champion_stats" do
    field :queue_id, :integer
    field :stats, :map

    belongs_to :summoner, Summoner,
      foreign_key: :summoner_puuid,
      references: :puuid,
      type: :string

    belongs_to :champion, Champion,
      foreign_key: :champion_id,
      references: :id,
      type: :integer
  end

  def changeset(champion_stat, attrs) do
    champion_stat
    |> cast(attrs, [:summoner_puuid, :champion_id, :queue_id, :stats])
    |> validate_required([:summoner_puuid, :champion_id, :queue_id])
  end
end
