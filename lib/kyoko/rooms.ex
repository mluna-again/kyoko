defmodule Kyoko.Rooms do
  @moduledoc """
  The Rooms context.
  """

  import Ecto.Query, warn: false
  alias Kyoko.Repo

  alias Kyoko.Rooms.Room
  alias Kyoko.Rooms.User
  alias Kyoko.Rooms.Settings

  def update_emojis!(room_code, emojis) do
    room = Repo.preload(get_room_by!(code: room_code), [:settings])

    room.settings
    |> Settings.update_changeset(%{emojis: emojis})
    |> Repo.update!()
  end

  def toggle_setting(room_code, setting_str) do
    room = Repo.preload(get_room_by!(code: room_code), [:settings])

    setting = Map.get(room.settings, String.to_existing_atom(setting_str))

    if setting do
      room.settings
      |> Settings.update_changeset(%{setting_str: !setting})
      |> Repo.update()
    end
  end

  def create_settings_for_room(%Room{} = room, %{} = default_settings \\ %{}) do
    Ecto.build_assoc(room, :settings, %Settings{})
    |> Settings.changeset(default_settings)
    |> Repo.insert()
  end

  def close_all_rooms do
    Repo.update_all(Room, set: [active: false])
  end

  def reset_room(room_code) do
    users =
      for user <- get_room_by!(code: room_code).users do
        {:ok, user} =
          user
          |> User.update_changeset(%{selection: nil})
          |> Repo.update()

        user
      end

    {:ok, users}
  end

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

  def set_user_as_inactive(room_code, player_name),
    do: set_user_status(room_code, player_name, false)

  def set_user_as_active(room_code, player_name),
    do: set_user_status(room_code, player_name, true)

  def set_user_status(room_code, player_name, status) do
    room = get_room_by!(code: room_code)

    user =
      from(user in User, where: user.room_id == ^room.id and user.name == ^player_name)
      |> Repo.one()

    if user do
      update_user(user, %{active: status})
    end
  end

  def set_room_as_inactive_if_empty(room_id) do
    unless has_active_users?(room_id) do
      set_room_as_inactive(room_id)
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
    rooms =
      from(room in Room, where: room.active == ^true)
      |> Repo.all()

    length(rooms) < 15
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
  def get_room!(id), do: Repo.get!(Room, id) |> Repo.preload([:users, :settings])
  def get_room_by!(params), do: Repo.get_by!(Room, params) |> Repo.preload([:users, :settings])

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

    with {:ok, _settings} <- create_settings_for_room(room) do
      {:ok, Repo.preload(room, [:users, :settings])}
    end
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
