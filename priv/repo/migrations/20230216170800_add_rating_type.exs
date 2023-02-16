defmodule Kyoko.Repo.Migrations.AddRatingType do
  use Ecto.Migration

  def up do
    execute "CREATE TYPE rating_type_enum AS ENUM ('shirts', 'cards');"
    execute "ALTER TABLE rooms ADD COLUMN rating_type rating_type_enum;"
  end

  def down do
    execute "ALTER TABLE rooms DROP COLUMN rating_type;"
    execute "DROP TYPE rating_type_enum;"
  end
end
