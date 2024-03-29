defmodule Kyoko.Issues do
  @moduledoc """
  The Issues context.
  """

  import Ecto.Query, warn: false
  alias Kyoko.Repo

  alias Kyoko.Issues.{Issue, IssueResponse}
  alias Kyoko.Rooms.Room

  @doc """
  Returns the list of issues.

  ## Examples

      iex> list_issues()
      [%Issue{}, ...]

  """
  def list_issues do
    Repo.all(Issue)
  end

  def list_issues_by_room(%Room{} = room) do
    Issue
    |> where([issue], issue.room_id == ^room.id)
    |> Repo.all()
  end

  @doc """
  Gets a single issue.

  Raises `Ecto.NoResultsError` if the Issue does not exist.

  ## Examples

      iex> get_issue!(123)
      %Issue{}

      iex> get_issue!(456)
      ** (Ecto.NoResultsError)

  """
  def get_issue!(id), do: Repo.get!(Issue, id)

  def get_issue_by!(params), do: Repo.get_by!(Issue, params)

  @doc """
  Creates a issue.

  ## Examples

      iex> create_issue(%{field: value})
      {:ok, %Issue{}}

      iex> create_issue(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_issue(%Room{} = room, attrs \\ %{}) do
    %Issue{}
    |> Issue.create_changeset(attrs, room)
    |> Repo.insert()
  end

  @doc """
  Updates a issue.

  ## Examples

      iex> update_issue(issue, %{field: new_value})
      {:ok, %Issue{}}

      iex> update_issue(issue, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_issue(%Issue{} = issue, attrs) do
    issue
    |> Issue.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a issue.

  ## Examples

      iex> delete_issue(issue)
      {:ok, %Issue{}}

      iex> delete_issue(issue)
      {:error, %Ecto.Changeset{}}

  """
  def delete_issue(%Issue{} = issue) do
    Repo.delete(issue)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking issue changes.

  ## Examples

      iex> change_issue(issue)
      %Ecto.Changeset{data: %Issue{}}

  """
  def change_issue(%Issue{} = issue, attrs \\ %{}) do
    Issue.changeset(issue, attrs)
  end

  def add_responses_to_issue!(issue, users) do
    issue_id = Map.get(issue, :id) || Map.get(issue, "id")

    responses =
      users
      |> Stream.filter(fn user -> user.selection end)
      |> Enum.map(fn user ->
        issue = %{
          issue_id: issue_id,
          user_id: user.id,
          selection: user.selection
        }

        %{valid?: true} = IssueResponse.changeset(%IssueResponse{}, issue)

        issue
      end)

    # delete old responses if this method is called again
    IssueResponse
    |> where([response], response.issue_id == ^issue_id)
    |> Repo.delete_all()

    Repo.insert_all(IssueResponse, responses)

    calculate_average_from_responses!(issue, responses)
  end

  defp calculate_average_from_responses!(issue, responses) do
    sum =
      Stream.map(responses, fn response -> response.selection end)
      |> Enum.sum()

    average = round(sum / Enum.count(responses))

    Issue.changeset(issue, %{result: average})
    |> Repo.update!()

    average
  end
end
