defmodule League.Stats.Match do
  use Ecto.Schema
  import Ecto.Changeset
  alias League.Stats.{Summoner, Champion}

  @primary_key false
  schema "matches" do
    field :id, :integer, primary_key: true
    field :start_time, :integer
    field :duration, :integer
    field :game_version, :string
    field :season_id, :integer
    field :queue_id, :integer
    field :did_win, :boolean
    field :role, :string
    field :stats, :map

    belongs_to :summoner, Summoner,
      foreign_key: :summoner_puuid,
      references: :puuid,
      type: :string,
      primary_key: true

    belongs_to :champion, Champion,
      foreign_key: :champion_id,
      references: :id,
      type: :integer
  end

  def changeset(match, attrs) do
    match
    |> cast(attrs, [
      :id,
      :summoner_puuid,
      :start_time,
      :duration,
      :game_version,
      :season_id,
      :queue_id,
      :did_win,
      :champion_id,
      :role,
      :stats
    ])
    |> validate_required([
      :id,
      :summoner_puuid,
      :start_time,
      :duration,
      :game_version,
      :season_id,
      :queue_id,
      :did_win,
      :champion_id
    ])
  end
end
