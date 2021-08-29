defmodule Hello.Repo.Migrations.CreateChampionStats do
  use Ecto.Migration

  def change do
    create table(:champion_stats) do
      add :summoner_puuid,
          references(:summoners, column: "puuid", type: :string, on_delete: :delete_all),
          null: false

      add :champion_id, references(:champions, type: :integer), null: false
      add :queue_id, :integer, null: false
      add :stats, :map
    end

    create(unique_index(:champion_stats, [:summoner_puuid, :champion_id, :queue_id]))
  end
end
