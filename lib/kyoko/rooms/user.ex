defmodule Kyoko.Rooms.User do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_teams ["black", "white"]

  schema "room_users" do
    field :name, :string
    field :selection, :integer
    field :active, :boolean, default: true
    field :team, :string
    belongs_to :room, Kyoko.Rooms.Room

    timestamps()
  end

  @doc false
  def changeset(user, attrs, teams_enabled) do
    user
    |> cast(attrs, [:name, :selection, :room_id, :active, :team])
    |> validate_required([:name, :room_id])
    |> validate_length(:name, max: 30)
    |> validate_team(teams_enabled)
  end

  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :selection, :active, :room_id])
    |> validate_length(:name, max: 30)
  end

  defp validate_team(%{changes: %{team: team}} = changeset, true) do
    if Enum.member?(@valid_teams, team) do
      changeset
    else
      add_error(changeset, :team, "is invalid")
    end
  end

  defp validate_team(changeset, true) do
    add_error(changeset, :team, "is required")
  end

  defp validate_team(changeset, _), do: changeset
end
