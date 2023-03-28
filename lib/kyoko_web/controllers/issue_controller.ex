defmodule KyokoWeb.IssueController do
  use KyokoWeb, :controller

  alias Kyoko.Issues
  alias Kyoko.Issues.Issue
  alias Kyoko.Rooms

  action_fallback KyokoWeb.FallbackController

  def index_by_room(conn, %{"room_code" => room_code}) do
    room = Rooms.get_room_by!(code: room_code)
    issues = Issues.list_issues_by_room(room)

    render(conn, "index.json", issues: issues)
  end

  def index(conn, _params) do
    issues = Issues.list_issues()
    render(conn, "index.json", issues: issues)
  end

  def create(conn, %{"issue" => issue_params}) do
    room_code = issue_params["room"]
    room = room_code && Rooms.get_room_by!(code: room_code)

    with room when not is_nil(room) <- room,
         {:ok, %Issue{} = issue} <- Issues.create_issue(room, issue_params) do
      conn
      |> put_status(:created)
      |> render("show.json", issue: issue)
    end
  end

  def show(conn, %{"id" => id}) do
    issue = Issues.get_issue!(id)
    render(conn, "show.json", issue: issue)
  end

  def update(conn, %{"id" => id, "issue" => issue_params}) do
    issue = Issues.get_issue!(id)

    with {:ok, %Issue{} = issue} <- Issues.update_issue(issue, issue_params) do
      render(conn, "show.json", issue: issue)
    end
  end

  def delete(conn, %{"id" => id}) do
    issue = Issues.get_issue!(id)

    with {:ok, %Issue{}} <- Issues.delete_issue(issue) do
      send_resp(conn, :no_content, "")
    end
  end
end
