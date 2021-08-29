defmodule League.Stats.Summoner do
  use Ecto.Schema
  import Ecto.Changeset
  alias League.Stats.{Match, ChampionStat}

  @primary_key {:puuid, :string, []}
  schema "summoners" do
    field :name, :string
    field :summoner_id, :string
    field :account_id, :string
    field :ranked_tiers, :map
    field :last_updated_timestamps, :map

    has_many :matches, Match, foreign_key: :summoner_puuid
    has_many :champion_stats, ChampionStat, foreign_key: :summoner_puuid
  end

  def changeset(summoner, attrs) do
    summoner
    |> cast(attrs, [
      :puuid,
      :name,
      :summoner_id,
      :account_id,
      :ranked_tiers,
      :last_updated_timestamps
    ])
    |> validate_required([:puuid, :name, :summoner_id, :account_id])
  end
end
