defmodule Kyoko.Repo.Migrations.AddTeamsColumnToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :teams_enabled, :boolean, null: false, default: false
    end

    alter table(:room_users) do
      add :team, :string, null: true
    end
  end
end
