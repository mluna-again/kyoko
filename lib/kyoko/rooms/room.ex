defmodule Kyoko.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :code, :string
    field :name, :string
    has_many :users, Kyoko.Rooms.User

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 4, max: 30)
    |> validate_format(:name, ~r/^[A-Z ]+$/i)
    |> put_code()
    |> unique_constraint(:code)
  end

  defp put_code(%{valid?: false} = changeset), do: changeset
  defp put_code(changeset) do
    put_change(changeset, :code, Ecto.UUID.generate())
  end
end
