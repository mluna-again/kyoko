defmodule KyokoWeb.RoomController do
  use KyokoWeb, :controller

  alias Kyoko.Rooms
  alias Kyoko.Rooms.Room
  alias Kyoko.Rooms.User
  alias Kyoko.Rooms.Settings
  alias KyokoWeb.Endpoint

  action_fallback KyokoWeb.FallbackController

  plug :check_for_rooms_available

  def selection(conn, %{"id" => id, "selection" => selection, "emoji" => emoji, "player" => player}) do
    user = Rooms.get_user_by_room!(id, player)
    selection = if user.selection == selection, do: nil, else: selection

    {:ok, user} = Rooms.update_user(user, %{selection: selection, emoji: emoji})

    Endpoint.broadcast("room_presence:#{id}", "update_user", %{
      player: player,
      selection: not is_nil(user.selection)
    })

    conn
    |> send_resp(:no_content, "")
  end

  def create(conn, %{"room" => %{"first" => first_user} = room}) do
    with {:ok, %Room{} = room} <- Rooms.create_room(room),
         {:ok, %Settings{} = _settings} <- Rooms.create_settings_for_room(room),
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

  defp check_for_rooms_available(conn, _opts) do
    if Application.get_env(:kyoko, :dev) || Rooms.are_rooms_available?() do
      conn
    else
      conn
      |> halt()
      |> send_resp(:service_unavailable, "")
    end
  end
end
