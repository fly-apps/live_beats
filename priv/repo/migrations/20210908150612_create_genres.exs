defmodule LiveBeats.Repo.Migrations.CreateGenres do
  use Ecto.Migration

  def change do
    create table(:genres) do
      add :title, :text, null: false
    end
  end
end
