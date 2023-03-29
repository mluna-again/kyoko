defmodule Kyoko.Repo.Migrations.AddIssueBeingVotedRefToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :issue_being_voted_id, references(:issues, on_delete: :nilify_all)
    end
  end
end
