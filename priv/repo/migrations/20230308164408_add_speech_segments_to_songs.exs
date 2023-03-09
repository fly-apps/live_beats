defmodule LiveBeats.Repo.Migrations.AddSpeechSegmentsToSongs do
  use Ecto.Migration

  def change do
    alter table(:songs) do
      add :speech_segments, {:array, :map}, null: false, default: []
    end
  end
end
