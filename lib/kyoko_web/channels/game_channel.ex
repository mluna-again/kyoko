defmodule KyokoWeb.GameChannel do
  @five_minutes 60 * 1000 * 5

  use KyokoWeb, :channel
  alias KyokoWeb.Presence
  alias Kyoko.Rooms
  alias Kyoko.PubSub
  alias KyokoWeb.RoomView

  @impl true
  def join("room:" <> room_id, %{"player" => player_name, "team" => team} = _payload, socket) do
    if authorized?(room_id) do
      send(self(), :after_join)

      socket =
        socket
        |> assign(:player_name, player_name)
        |> assign(:team, team)
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
      :timer.apply_after(@five_minutes, Rooms, :set_room_as_inactive_if_empty, [room_id])
    end
  end

  @impl true
  def handle_in(
        "user_selection",
        %{"player" => name, "selection" => selection, "emoji" => emoji} = payload,
        socket
      ) do
    {:ok, user} =
      Rooms.get_user_by_room!(socket.assigns.room_id, name)
      |> Rooms.update_user(%{selection: selection})

    Presence.update(
      self(),
      socket.assigns.room_id,
      socket.assigns.player_name,
      Map.put(format_user(socket, user), :emoji, emoji)
    )

    broadcast(socket, "user_selection", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_in("user_selection", %{"player" => _name} = payload, socket) do
    handle_in("user_selection", Map.merge(payload, %{"selection" => nil}), socket)
  end

  @impl true
  def handle_in("reveal_cards", _payload, socket) do
    {:ok, _room} =
      Rooms.get_room_by!(code: socket.assigns.room_id)
      |> Rooms.update_room(%{status: "game_over"})

    broadcast(socket, "reveal_cards", %{})
    {:noreply, socket}
  end

  @impl true
  def handle_in("change_emojis", %{"emojis" => emojis} = payload, socket) do
    Rooms.update_emojis!(socket.assigns.room_id, emojis)
    broadcast(socket, "change_emojis", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_in("reset_room", _payload, socket) do
    spawn(fn ->
      {:ok, _users} = Rooms.reset_room(socket.assigns.room_id)
    end)

    broadcast(socket, "reset_room", %{})
    {:noreply, socket}
  end

  @impl true
  def handle_in("toggle_" <> setting, %{"active" => active}, socket) do
    Rooms.toggle_setting(socket.assigns.room_id, setting, active)
    broadcast(socket, "toggle_#{setting}", %{active: active})
    {:noreply, socket}
  end

  @impl true
  def handle_in("reset_user", _payload, socket) do
    Presence.update(self(), socket.assigns.room_id, socket.assigns.player_name, format_user(socket, socket.whole_user))

    {:noreply, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    room = Rooms.get_room_by!(code: socket.assigns.room_id)

    {:ok, user} =
      Rooms.add_user_to_room(room, %{
        name: socket.assigns.player_name,
        team: socket.assigns.team
      })

    Rooms.set_user_as_active(socket.assigns.room_id, socket.assigns.player_name)

    {:ok, _} =
      Presence.track(
        self(),
        socket.assigns.room_id,
        socket.assigns.player_name,
        format_user(socket, user)
      )

    Phoenix.PubSub.subscribe(PubSub, socket.assigns.room_id)

    push(socket, "presence_state", Presence.list(socket.assigns.room_id))
    {:noreply, assign(socket, :whole_user, user)}
  end

  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    broadcast(socket, "presence_diff", payload)
    {:noreply, socket}
  end

  defp format_user(socket, user) do
    Map.merge(
      %{
        online_at: inspect(System.system_time(:second)),
        name: socket.assigns.player_name,
        selection: user.selection
      },
      RoomView.render("user.json", %{user: user})
    )
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
