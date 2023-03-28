defmodule Kyoko.Issues.Issue do
  use Ecto.Schema
  import Ecto.Changeset

  alias Kyoko.Rooms.Room

  schema "issues" do
    field :description, :string
    field :title, :string
    belongs_to :room, Room

    timestamps()
  end

  @doc false
  def changeset(issue, attrs) do
    issue
    |> cast(attrs, [:title, :description, :room_id])
    |> validate_required([:title, :room_id])
  end

  def create_changeset(issue, attrs, room) do
    issue
    |> change()
    |> put_change(:room_id, room.id)
    |> changeset(attrs)
  end
end
