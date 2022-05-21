defmodule KyokoWeb.GameChannel do
  use KyokoWeb, :channel
  alias KyokoWeb.Presence
  alias Kyoko.PubSub

  require Logger

  @impl true
  def join("room:" <> room_id, %{"player" => player_name} = payload, socket) do
    if authorized?(payload) do
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

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (game:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
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
  defp authorized?(_payload) do
    true
  end
end
