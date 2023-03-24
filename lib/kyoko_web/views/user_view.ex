defmodule KyokoWeb.UserView do
  use KyokoWeb, :view

  def render("show.json", %{user: user}) do
    %{
      id: user.id,
      name: user.name,
      room_id: user.room_id,
      inserted_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end
end
