defmodule Kyoko.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_states ["playing", "game_over"]
  @valid_rating_types ["shirts", "cards"]

  schema "rooms" do
    field :code, :string
    field :name, :string
    field :active, :boolean, default: true
    field :status, :string, default: "playing"
    field :teams_enabled, :boolean, default: false
    field :rating_type, :string, default: "shirts"
    has_many :users, Kyoko.Rooms.User
    has_one :settings, Kyoko.Rooms.Settings

    timestamps()
  end

  defp _changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :active, :teams_enabled, :status, :rating_type])
    |> validate_required([:name])
    |> validate_length(:name, max: 30)
    |> unique_constraint(:code)
    |> validate_inclusion(:status, @valid_states)
    |> validate_inclusion(:rating_type, @valid_rating_types)
  end

  @doc false
  def changeset(room, attrs) do
    _changeset(room, attrs)
    |> put_code()
  end

  def update_changeset(room, attrs) do
    _changeset(room, attrs)
  end

  defp put_code(%{valid?: false} = changeset), do: changeset

  defp put_code(changeset) do
    put_change(changeset, :code, Ecto.UUID.generate())
  end
end
