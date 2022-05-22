defmodule Kyoko.Repo.Migrations.AddActiveColumnToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :active, :boolean
    end
  end
end
