defmodule Kyoko.Issues.IssueResponse do
  use Ecto.Schema
  import Ecto.Changeset

  alias Kyoko.Issues.Issue
  alias Kyoko.Rooms.User

  schema "issue_responses" do
    field :selection, :integer
    belongs_to :issue, Issue
    belongs_to :user, User
  end

  def changeset(response, attrs) do
    response
    |> cast(attrs, [:selection, :user_id, :issue_id])
    |> validate_required([:selection, :user_id, :issue_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:issue_id)
  end
end
