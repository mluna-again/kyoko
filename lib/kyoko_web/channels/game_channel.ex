defmodule KyokoWeb.GameChannel do
  use KyokoWeb, :channel
  alias KyokoWeb.Presence
  alias Kyoko.Rooms
  alias Kyoko.PubSub

  @impl true
  def join("room:" <> room_id, %{"player" => player_name} = _payload, socket) do
    if authorized?(room_id) do
      send(self(), :after_join)

      socket =
        socket
        |> assign(:player_name, player_name)
        |> assign(:room_id, room_id)

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def terminate(reason, socket) do
    room_id = socket.assigns.room_id
    player_name = socket.assigns.player_name

    Rooms.set_user_as_inactive(room_id, player_name)

    unless Rooms.has_active_users?(room_id) do
      Rooms.set_room_as_inactive(room_id)
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    room = Rooms.get_room_by!(code: socket.assigns.room_id)

    {:ok, _user} =
      Rooms.add_user_to_room(room, %{
        name: socket.assigns.player_name
      })

    {:ok, _} =
      Presence.track(self(), socket.assigns.room_id, socket.assigns.player_name, %{
        online_at: inspect(System.system_time(:second)),
        name: socket.assigns.player_name
      })

    Phoenix.PubSub.subscribe(PubSub, socket.assigns.room_id)

    push(socket, "presence_state", Presence.list(socket.assigns.room_id))
    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    broadcast(socket, "presence_diff", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(room_id) do
    try do
      Rooms.get_room_by!(code: room_id)
      |> Map.get(:active)
    rescue
      _e -> false
    end
  end
end
