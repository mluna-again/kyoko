defmodule KyokoWeb.PingController do
  use KyokoWeb, :controller

  def pong(conn, _params) do
    conn
    |> put_status(:ok)
    |> text("pong")
  end
end
