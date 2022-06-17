defmodule Kyoko.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :code, :string
    field :name, :string
    field :active, :boolean, default: true
    has_many :users, Kyoko.Rooms.User
    has_one :settings, Kyoko.Rooms.Settings

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :active])
    |> validate_required([:name])
    |> validate_length(:name, max: 30)
    |> put_code()
    |> unique_constraint(:code)
  end

  def update_changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :active])
    |> validate_required([:name])
    |> validate_length(:name, max: 30)
    |> unique_constraint(:code)
  end

  defp put_code(%{valid?: false} = changeset), do: changeset
  defp put_code(changeset) do
    put_change(changeset, :code, Ecto.UUID.generate())
  end
end
