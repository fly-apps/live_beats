defmodule LiveBeats.Repo.Migrations.CreateGenres do
  use Ecto.Migration

  def change do
    create table(:genres) do
      add :title, :text, null: false
      add :slug, :text, null: false
    end

    create unique_index(:genres, [:title])
    create unique_index(:genres, [:slug])
  end
end
