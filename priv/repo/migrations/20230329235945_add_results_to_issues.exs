defmodule Kyoko.Repo.Migrations.AddResultsToIssues do
  use Ecto.Migration

  def change do
    alter table(:issues) do
      add :result, :integer
    end
  end
end
