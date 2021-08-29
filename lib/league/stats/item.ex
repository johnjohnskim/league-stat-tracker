defmodule League.Stats.Item do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, []}
  schema "items" do
    field :name, :string
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:id, :name])
    |> validate_required([:id, :name])
  end
end
