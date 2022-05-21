defmodule Kyoko.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :code, :string
      add :name, :string

      timestamps()
    end

    create unique_index(:rooms, [:code])
  end
end
