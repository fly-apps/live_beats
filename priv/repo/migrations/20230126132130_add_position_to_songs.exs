defmodule LiveBeats.Repo.Migrations.AddPositionToSongs do
  use Ecto.Migration

  def change do
    alter table(:songs) do
      add :position, :integer, null: false, default: 0
    end
  end
end
