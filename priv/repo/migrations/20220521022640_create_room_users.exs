defmodule Kyoko.Repo.Migrations.CreateRoomUsers do
  use Ecto.Migration

  def change do
    create table(:room_users) do
      add :name, :string
      add :selection, :integer
      add :room_id, references(:rooms, on_delete: :delete_all)

      timestamps()
    end

    create index(:room_users, [:room_id])
  end
end
