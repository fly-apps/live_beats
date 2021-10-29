defmodule LiveBeats.Repo.Migrations.CreateSongs do
  use Ecto.Migration

  def change do
    create table(:songs) do
      add :album_artist, :string
      add :artist, :string
      add :duration, :integer
      add :title, :string
      add :date_recorded, :naive_datetime
      add :date_released, :naive_datetime
      add :user_id, references(:users, on_delete: :nothing)
      add :genre_id, references(:genres, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:songs, [:user_id, :title, :artist])
    create index(:songs, [:user_id])
    create index(:songs, [:genre_id])
  end
end
