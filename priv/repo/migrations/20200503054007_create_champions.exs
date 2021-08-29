defmodule Hello.Repo.Migrations.CreateChampions do
  use Ecto.Migration

  def change do
    create table(:champions, primary_key: false) do
      add :id, :integer, primary_key: true
      add :name, :string, null: false
      add :key, :string
    end
  end
end
