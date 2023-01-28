defmodule Kyoko.Repo.Migrations.AddStatusToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :status, :string
    end
  end
end
