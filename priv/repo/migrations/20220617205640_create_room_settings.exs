defmodule Kyoko.Repo.Migrations.CreateRoomSettings do
  use Ecto.Migration

  def change do
    create table(:room_settings) do
      add :clock, :boolean, default: false, null: false
      add :animation, :boolean, default: false, null: false
      add :emojis, :string
      add :room_id, references(:rooms, on_delete: :nothing)

      timestamps()
    end

    create index(:room_settings, [:room_id])
  end
end
