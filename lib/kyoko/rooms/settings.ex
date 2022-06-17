defmodule Kyoko.Rooms.Settings do
  use Ecto.Schema
  import Ecto.Changeset

  schema "room_settings" do
    field :animation, :boolean, default: false
    field :clock, :boolean, default: false
    field :emojis, :string
    belongs_to :room, Kyoko.Rooms.Room

    timestamps()
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:clock, :animation, :emojis])
    |> put_emojis()
    |> validate_required([:clock, :animation, :emojis])
  end

  defp put_emojis(%Ecto.Changeset{} = changeset), do: put_change(changeset, :emojis, "😑👍")
end
