defmodule Kyoko.RoomsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Kyoko.Rooms` context.
  """

  @doc """
  Generate a unique room code.
  """
  def unique_room_code, do: "some code#{System.unique_integer([:positive])}"

  @doc """
  Generate a room.
  """
  def room_fixture(attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> Enum.into(%{
        code: unique_room_code(),
        name: "some name"
      })
      |> Kyoko.Rooms.create_room()

    room
  end
end
