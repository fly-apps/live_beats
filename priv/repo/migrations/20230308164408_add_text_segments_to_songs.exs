defmodule LiveBeats.Repo.Migrations.AddLyricsToSongs do
  use Ecto.Migration

  def change do
    alter table(:songs) do
      add :text_segments, {:array, :map}, null: false, default: []
    end
  end
end
