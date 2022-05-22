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
  def terminate(_reason, socket) do
    room_id = socket.assigns.room_id
    player_name = socket.assigns.player_name

    Rooms.set_user_as_inactive(room_id, player_name)

    unless Rooms.has_active_users?(room_id) do
      terminate_room_if_not_in_dev(room_id)
    end
  end

  @impl true
  def handle_in("user_selection", %{"player" => name, "selection" => selection} = payload, socket) do
    {:ok, _user} =
      Rooms.get_user_by_room!(socket.assigns.room_id, name)
      |> Rooms.update_user(%{selection: selection})

    broadcast(socket, "user_selection", payload)
    {:noreply, socket}
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

  defp terminate_room_if_not_in_dev(room_id) do
    unless Application.get_env(:kyoko, :dev, false) do
      Rooms.set_room_as_inactive(room_id)
    end
  end
end
