defmodule Kyoko.Rooms.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "room_users" do
    field :name, :string
    field :selection, :integer
    belongs_to :room, Kyoko.Rooms.Room

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :selection, :room_id])
    |> validate_required([:name, :room_id])
  end
end
