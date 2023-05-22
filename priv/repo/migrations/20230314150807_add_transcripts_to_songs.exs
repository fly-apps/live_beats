defmodule LiveBeats.Repo.Migrations.AddTranscriptsToSongs do
  use Ecto.Migration

  def change do
    alter table(:songs) do
      add :transcript_segments, {:array, :map}, null: false, default: []
    end
  end
end
