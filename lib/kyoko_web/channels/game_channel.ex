defmodule KyokoWeb.GameChannel do
  @five_minutes 60 * 1000 * 5

  use KyokoWeb, :channel
  alias KyokoWeb.Presence
  alias Kyoko.{Rooms, Issues}
  alias Kyoko.PubSub
  alias KyokoWeb.RoomView

  @impl true
  def join("room:" <> room_code, %{"player" => player_name, "team" => team} = _payload, socket) do
    if authorized?(room_code) do
      send(self(), :after_join)

      socket =
        socket
        |> assign(:player_name, player_name)
        |> assign(:team, team)
        |> assign(:room_code, room_code)

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def terminate(_reason, socket) do
    room_code = socket.assigns.room_code
    player_name = socket.assigns.player_name

    Rooms.set_user_as_inactive(room_code, player_name)

    unless Rooms.has_active_users?(room_code) do
      :timer.apply_after(@five_minutes, Rooms, :set_room_as_inactive_if_empty, [room_code])
    end
  end

  @impl true
  def handle_in("reveal_cards", _payload, socket) do
    {:ok, room} =
      Rooms.get_room_by!(code: socket.assigns.room_code)
      |> Rooms.update_room(%{status: "game_over"})

    result =
      if room.issue_being_voted_id do
        issue = room.issue_being_voted
        Issues.add_responses_to_issue!(issue, room.users)
      end

    users_with_selection = Enum.map(room.users, fn u -> format_user_with_selection(socket, u) end)
    broadcast(socket, "reveal_cards", %{users: users_with_selection})
    broadcast(socket, "users:update_selections", %{users: users_with_selection})

    broadcast(socket, "issues:new_result", %{result: result, issue_id: room.issue_being_voted_id})
    {:noreply, socket}
  end

  @impl true
  def handle_in("change_emojis", %{"emojis" => emojis} = payload, socket) do
    Rooms.update_emojis!(socket.assigns.room_code, emojis)
    broadcast(socket, "change_emojis", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_in("reset_room", _payload, socket) do
    {:ok, _users} = Rooms.reset_room(socket.assigns.room_code)

    broadcast(socket, "reset_room", %{})
    {:noreply, socket}
  end

  @impl true
  def handle_in("toggle_emojis", %{"active" => active}, socket) do
    broadcast(socket, "toggle_emojis", %{active: active})
    {:noreply, socket}
  end

  @impl true
  def handle_in("toggle_" <> setting, %{"active" => active}, socket) do
    Rooms.toggle_setting(socket.assigns.room_code, setting, active)
    broadcast(socket, "toggle_#{setting}", %{active: active})
    {:noreply, socket}
  end

  @impl true
  def handle_in("reset_user", _payload, socket) do
    Presence.update(
      self(),
      socket.assigns.room_code,
      socket.assigns.player_name,
      cleanup_user(socket, socket.assigns.whole_user)
    )

    {:noreply, socket}
  end

  @impl true
  def handle_in("issues:clearVote", payload, socket) do
    broadcast(socket, "issues:clearVote", payload)

    {:ok, _room} =
      Rooms.get_room_by!(code: socket.assigns.room_code)
      |> Rooms.update_room(%{issue_being_voted_id: nil})

    socket = assign(socket, :issue_being_voted, nil)
    {:noreply, socket}
  end

  def handle_in("issues:setVote", payload, socket) do
    broadcast(socket, "issues:setVote", payload)

    {:ok, _room} =
      Rooms.get_room_by!(code: socket.assigns.room_code)
      |> Rooms.update_room(%{issue_being_voted_id: payload["id"]})

    socket = assign(socket, :issue_being_voted, payload)
    {:noreply, socket}
  end

  @impl true
  def handle_in("issues:new", payload, socket) do
    broadcast(socket, "issues:new", payload)

    {:noreply, socket}
  end

  @impl true
  def handle_in("issues:delete", payload, socket) do
    broadcast(socket, "issues:delete", payload)

    {:noreply, socket}
  end

  @impl true
  def handle_in("user:kick", %{"name" => user_name}, socket) do
    user = Rooms.get_user_by!(name: user_name, room_id: socket.assigns.room.id)

    {:ok, _user} = Rooms.remove_user_from_room(socket.assigns.room, user)

    broadcast(socket, "user:kicked", %{name: user_name})
    {:reply, :ok, socket}
  end

  # safari doesn't want to work like a normal browser,
  # so i need to resend this event for safari to pick up
  @impl true
  def handle_in("startup:sync", _payload, socket) do
    send_presence_list(socket)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    room = Rooms.get_room_by!(code: socket.assigns.room_code)

    {:ok, user} =
      Rooms.add_user_to_room(room, %{
        name: socket.assigns.player_name,
        team: socket.assigns.team
      })

    Rooms.set_user_as_active(socket.assigns.room_code, socket.assigns.player_name)

    {:ok, _} =
      Presence.track(
        self(),
        socket.assigns.room_code,
        socket.assigns.player_name,
        format_user(socket, user)
      )

    Phoenix.PubSub.subscribe(PubSub, socket.assigns.room_code)
    KyokoWeb.Endpoint.subscribe("room_presence:" <> socket.assigns.room_code)

    send_presence_list(socket)

    socket =
      assign(socket, :whole_user, user)
      |> assign(:room, room)

    {:noreply, assign(socket, :whole_user, user)}
  end

  def handle_info(%{topic: "room_presence:" <> _, event: "update_user", payload: meta}, socket) do
    %{} = user = Rooms.get_user_by_room!(socket.assigns.room_code, meta.player)

    Presence.update(
      self(),
      socket.assigns.room_code,
      user.name,
      format_user(socket, user)
    )

    broadcast(socket, "user_selection", meta)
    {:noreply, socket}
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
        selection: not is_nil(user.selection)
      },
      RoomView.render("user.json", %{user: user})
    )
  end

  defp format_user_with_selection(socket, user) do
    Map.merge(
      %{
        online_at: inspect(System.system_time(:second)),
        name: socket.assigns.player_name,
        selection: user.selection
      },
      RoomView.render("user.json", %{user: user})
    )
  end

  defp cleanup_user(socket, user) do
    format_user(socket, user)
    |> Map.put(:selection, nil)
    |> Map.put(:emoji, nil)
  end

  defp send_presence_list(socket) do
    push(socket, "presence_state", Presence.list(socket.assigns.room_code))
  end

  # Add authorization logic here as required.
  defp authorized?(room_code) do
    try do
      Rooms.get_room_by!(code: room_code)
      |> Map.get(:active)
    rescue
      _e -> false
    end
  end
end
