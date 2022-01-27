defmodule LiveBeats.Repo.Migrations.AddFileSizeToSongs do
  use Ecto.Migration

  def change do
    alter table(:songs) do
      add :mp3_filesize, :integer, null: false, default: 0
    end
  end
end
