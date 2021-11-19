defmodule LiveBeats.Repo.Migrations.AddSongsNumberToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :songs_count, :integer, null: false, default: 0
    end

    execute("
      UPDATE users set songs_count =
        (SELECT count (*) from songs
          where songs.user_id = users.id)")
  end

  def down do
    alter table(:users) do
      remove :songs_count
    end
  end
end
