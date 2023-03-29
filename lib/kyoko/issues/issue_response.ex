defmodule Kyoko.Issues.IssueResponse do
  use Ecto.Schema

  alias Kyoko.Issues.Issue
  alias Kyoko.Rooms.User

  schema "issue_responses" do
    field :selection, :integer
    belongs_to :issue, Issue
    belongs_to :user, User
  end
end
