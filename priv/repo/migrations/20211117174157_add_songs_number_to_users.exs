defmodule LiveBeats.Repo.Migrations.AddSongsNumberToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :songs_count, :integer, null: false, default: 0
    end
  end

  def down do
    alter table(:users) do
      remove :songs_count
    end
  end
end
