defmodule Kyoko.Rooms.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "room_users" do
    field :name, :string
    field :selection, :integer
    field :active, :boolean, default: true
    belongs_to :room, Kyoko.Rooms.Room

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :selection, :room_id, :active])
    |> validate_required([:name, :room_id])
    |> validate_length(:name, max: 30)
  end

  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :selection, :active, :room_id])
    |> validate_length(:name, max: 30)
  end
end
