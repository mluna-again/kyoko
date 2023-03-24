defmodule KyokoWeb.UserController do
  use KyokoWeb, :controller

  alias Kyoko.Rooms

  action_fallback KyokoWeb.FallbackController

  def update(conn, %{"user" => user_name, "room_code" => room} = params) do
    room = Rooms.get_room_by!(code: room)
    user = Rooms.get_user_by!(name: user_name, room_id: room.id)

    with {:ok, user} <- Rooms.update_user(user, params) do

      payload = %{name: user.name, old_name: user_name}
      KyokoWeb.Endpoint.broadcast("room:#{room.code}", "user:update", payload)

      conn
      |> put_status(:ok)
      |> render("show.json", user: user)
    end
  end
end
