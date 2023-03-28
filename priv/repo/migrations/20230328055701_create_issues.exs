defmodule Kyoko.Repo.Migrations.CreateIssues do
  use Ecto.Migration

  def change do
    create table(:issues) do
      add :title, :string
      add :description, :text
      add :room_id, references(:rooms, on_delete: :delete_all)

      timestamps()
    end

    create index(:issues, [:room_id])
  end
end
