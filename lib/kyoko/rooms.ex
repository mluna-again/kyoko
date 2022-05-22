defmodule Kyoko.Rooms do
  @moduledoc """
  The Rooms context.
  """

  import Ecto.Query, warn: false
  alias Kyoko.Repo

  alias Kyoko.Rooms.Room
  alias Kyoko.Rooms.User

  def get_user_by!(params), do: Repo.get_by!(User, params)

  def get_user_by_room!(room_code, user_name) do
    room = get_room_by!(code: room_code)
    get_user_by!(name: user_name, room_id: room.id)
  end

  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def set_user_as_inactive(room_code, player_name) do
    room = get_room_by!(code: room_code)

    user =
      from(user in User, where: user.room_id == ^room.id and user.name == ^player_name)
      |> Repo.one()

    if user do
      user
      |> User.changeset(%{active: false})
      |> Repo.update()
    end
  end

  def set_room_as_inactive(room_code) do
    get_room_by!(code: room_code)
    |> Room.update_changeset(%{active: false})
    |> Repo.update()
  end

  def has_active_users?(room_code) do
    room = get_room_by!(code: room_code)

    Repo.get_by(User, room_id: room.id, active: true)
    |> case do
      nil ->
        false

      _ ->
        true
    end
  end

  def are_rooms_available?() do
    from(room in Room, where: room.active == ^true)
    |> Repo.all()
    |> case do
      nil -> true
      rooms -> length(rooms) < 3
    end
  end

  def add_user_to_room(room, user) do
    username = Map.get(user, "name") || Map.get(user, :name)

    case Repo.get_by(User, name: username, room_id: room.id) do
      nil ->
        %User{room_id: room.id}
        |> User.changeset(user)
        |> Repo.insert()

      user ->
        {:ok, user}
    end
  end

  @doc """
  Returns the list of rooms.

  ## Examples

      iex> list_rooms()
      [%Room{}, ...]

  """
  def list_rooms do
    Repo.all(Room)
  end

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.

  ## Examples

      iex> get_room!(123)
      %Room{}

      iex> get_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room!(id), do: Repo.get!(Room, id) |> Repo.preload([:users])
  def get_room_by!(params), do: Repo.get_by!(Room, params) |> Repo.preload([:users])

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

      iex> create_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room(attrs \\ %{}) do
    {:ok, room} =
      %Room{}
      |> Room.changeset(attrs)
      |> Repo.insert()

    {:ok, Repo.preload(room, [:users])}
  end

  @doc """
  Updates a room.

  ## Examples

      iex> update_room(room, %{field: new_value})
      {:ok, %Room{}}

      iex> update_room(room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room.

  ## Examples

      iex> delete_room(room)
      {:ok, %Room{}}

      iex> delete_room(room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room changes.

  ## Examples

      iex> change_room(room)
      %Ecto.Changeset{data: %Room{}}

  """
  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end
end
