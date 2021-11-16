defmodule LiveBeats.Repo.Migrations.AddAvatarUrlToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :avatar_url, :string
      add :external_homepage_url, :string
    end
  end
end
