defmodule Kyoko.IssuesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Kyoko.Issues` context.
  """

  @doc """
  Generate a issue.
  """
  def issue_fixture(attrs \\ %{}) do
    {:ok, issue} =
      attrs
      |> Enum.into(%{
        description: "some description",
        title: "some title"
      })
      |> Kyoko.Issues.create_issue()

    issue
  end
end
