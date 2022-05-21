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
      users: render_many(room.users, __MODULE__, "user.json", as: :user)
    }
  end

  def render("user.json", %{user: user}) do
    %{name: user.name}
  end
end
