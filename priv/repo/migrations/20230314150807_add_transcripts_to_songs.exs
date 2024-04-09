defmodule LiveBeats.Repo.Migrations.AddTranscriptsToSongs do
  use Ecto.Migration

  def change do
    alter table(:songs) do
      add :transcript, :jsonb, null: false, default: "{\"segments\": []}"
    end
  end
end
