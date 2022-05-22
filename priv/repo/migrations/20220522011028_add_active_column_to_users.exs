defmodule Kyoko.Repo.Migrations.AddActiveColumnToUsers do
  use Ecto.Migration

  def change do
    alter table(:room_users) do
      add :active, :boolean
    end
  end
end
