defmodule Hello.Repo.Migrations.CreateSummoners do
  use Ecto.Migration

  def change do
    create table(:summoners, primary_key: false) do
      add :puuid, :string, primary_key: true
      add :name, :string, null: false
      add :summoner_id, :string, null: false
      add :account_id, :string, null: false
      add :ranked_tiers, :map
      add :last_updated_timestamps, :map
    end
  end
end
