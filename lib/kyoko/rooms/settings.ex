defmodule Kyoko.Rooms.Settings do
  use Ecto.Schema
  import Ecto.Changeset

  schema "room_settings" do
    field :animation, :boolean, default: false
    field :clock, :boolean, default: false
    field :emojis, :string
    field :room_id, :id

    timestamps()
  end

  @doc false
  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:clock, :animation, :emojis])
    |> validate_required([:clock, :animation, :emojis])
  end
end
