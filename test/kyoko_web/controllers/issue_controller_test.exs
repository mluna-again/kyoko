defmodule KyokoWeb.IssueControllerTest do
  use KyokoWeb.ConnCase

  import Kyoko.IssuesFixtures

  alias Kyoko.Issues.Issue

  @create_attrs %{
    description: "some description",
    title: "some title"
  }
  @update_attrs %{
    description: "some updated description",
    title: "some updated title"
  }
  @invalid_attrs %{description: nil, title: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all issues", %{conn: conn} do
      conn = get(conn, Routes.issue_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create issue" do
    test "renders issue when data is valid", %{conn: conn} do
      conn = post(conn, Routes.issue_path(conn, :create), issue: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.issue_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "description" => "some description",
               "title" => "some title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.issue_path(conn, :create), issue: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update issue" do
    setup [:create_issue]

    test "renders issue when data is valid", %{conn: conn, issue: %Issue{id: id} = issue} do
      conn = put(conn, Routes.issue_path(conn, :update, issue), issue: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.issue_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "description" => "some updated description",
               "title" => "some updated title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, issue: issue} do
      conn = put(conn, Routes.issue_path(conn, :update, issue), issue: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete issue" do
    setup [:create_issue]

    test "deletes chosen issue", %{conn: conn, issue: issue} do
      conn = delete(conn, Routes.issue_path(conn, :delete, issue))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.issue_path(conn, :show, issue))
      end
    end
  end

  defp create_issue(_) do
    issue = issue_fixture()
    %{issue: issue}
  end
end
