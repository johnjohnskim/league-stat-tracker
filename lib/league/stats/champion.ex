defmodule League.Stats.Champion do
  use Ecto.Schema
  import Ecto.Changeset
  alias League.Stats.{Match, ChampionStat}

  @primary_key {:id, :integer, []}
  schema "champions" do
    field :name, :string
    field :key, :string
    has_many :matches, Match, foreign_key: :champion_id
    has_many :champion_stats, ChampionStat, foreign_key: :champion_id
  end

  def changeset(champion, attrs) do
    champion
    |> cast(attrs, [:id, :name, :key])
    |> validate_required([:id, :name, :key])
  end
end
