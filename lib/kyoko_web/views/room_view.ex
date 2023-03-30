defmodule KyokoWeb.RoomView do
  use KyokoWeb, :view
  alias KyokoWeb.RoomView

  def render("index.json", %{rooms: rooms}) do
    %{data: render_many(rooms, RoomView, "room.json")}
  end

  def render("show.json", %{room: room}) do
    %{data: render_one(room, RoomView, "room.json")}
  end

  def render("room.json", %{room: room}) do
    %{
      id: room.id,
      code: room.code,
      name: room.name,
      users: render_many(room.users, __MODULE__, "user.json", as: :user),
      settings: render_one(room.settings, __MODULE__, "settings.json", as: :settings),
      status: room.status,
      teams_enabled: room.teams_enabled,
      rating_type: room.rating_type,
      issue_being_voted: issue_being_voted(room.issue_being_voted)
    }
  end

  def render("user.json", %{user: user}) do
    %{name: user.name, team: user.team}
  end

  def render("settings.json", %{settings: settings}) do
    %{
      clock: settings.clock,
      animation: settings.animation,
      emojis: settings.emojis
    }
  end

  defp issue_being_voted(%Ecto.Association.NotLoaded{}), do: nil
  defp issue_being_voted(nil), do: nil

  defp issue_being_voted(issue) do
    %{
      id: issue.id,
      title: issue.title,
      description: issue.description,
      result: issue.result
    }
  end
end
