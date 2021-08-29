defmodule Hello.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items, primary_key: false) do
      add :id, :integer, primary_key: true
      add :name, :string, null: false
    end
  end
end
