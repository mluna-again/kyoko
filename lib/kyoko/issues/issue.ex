defmodule Kyoko.Issues.Issue do
  use Ecto.Schema
  import Ecto.Changeset

  alias Kyoko.Rooms.Room
  alias Kyoko.Issues.IssueResponse

  schema "issues" do
    field :description, :string
    field :title, :string
    field :result, :integer
    belongs_to :room, Room
    has_many :responses, IssueResponse

    timestamps()
  end

  @doc false
  def changeset(issue, attrs) do
    issue
    |> cast(attrs, [:title, :description, :room_id, :result])
    |> validate_required([:title, :room_id])
  end

  def create_changeset(issue, attrs, room) do
    issue
    |> change()
    |> put_change(:room_id, room.id)
    |> changeset(attrs)
  end
end
