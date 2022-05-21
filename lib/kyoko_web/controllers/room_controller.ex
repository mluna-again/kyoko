defmodule KyokoWeb.RoomController do
  use KyokoWeb, :controller

  alias Kyoko.Rooms
  alias Kyoko.Rooms.Room
  alias Kyoko.Rooms.User

  action_fallback KyokoWeb.FallbackController

  def create(conn, %{"room" => %{"first" => first_user} = room}) do
    with {:ok, %Room{} = room} <- Rooms.create_room(room),
         {:ok, %User{} = user} <- Rooms.add_user_to_room(room, first_user) do
      conn
      |> put_status(:created)
      |> render("show.json", room: room, user: user)
    end
  end

  def show(conn, %{"id" => room_code}) do
    room = Rooms.get_room_by!(code: room_code)
    render(conn, "show.json", room: room)
  end

  def update(conn, %{"id" => id, "room" => room_params}) do
    room = Rooms.get_room!(id)

    with {:ok, %Room{} = room} <- Rooms.update_room(room, room_params) do
      render(conn, "show.json", room: room)
    end
  end
end
