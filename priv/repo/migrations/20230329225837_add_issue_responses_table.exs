defmodule Kyoko.Repo.Migrations.AddIssueResponsesTable do
  use Ecto.Migration

  def change do
    create table(:issue_responses) do
      add :issue_id, references(:issues, on_delete: :delete_all), null: false
      add :user_id, references(:room_users, on_delete: :nilify_all), null: false
      add :selection, :integer, null: false
    end
  end
end
