defmodule Hello.Repo.Migrations.CreateMatches do
  use Ecto.Migration

  def change do
    create table(:matches, primary_key: false) do
      add :id, :bigint, primary_key: true

      add :summoner_puuid,
          references(:summoners, column: "puuid", type: :string, on_delete: :delete_all),
          null: false,
          primary_key: true

      add :start_time, :bigint, null: false
      add :duration, :integer, null: false
      add :game_version, :string, null: false
      add :season_id, :integer, null: false
      add :queue_id, :integer, null: false
      add :did_win, :boolean, null: false
      add :champion_id, references(:champions, type: :integer), null: false
      add :role, :string
      add :stats, :map
    end
  end
end
