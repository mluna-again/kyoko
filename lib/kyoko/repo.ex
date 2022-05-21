defmodule Kyoko.Repo do
  use Ecto.Repo,
    otp_app: :kyoko,
    adapter: Ecto.Adapters.Postgres
end
