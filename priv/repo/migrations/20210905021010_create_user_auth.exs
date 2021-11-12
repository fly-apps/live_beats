defmodule LiveBeats.Repo.Migrations.CreateUserAuth do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :email, :citext, null: false
      add :username, :string, null: false
      add :name, :string
      add :role, :string, null: false
      add :confirmed_at, :naive_datetime
      add :profile_tagline, :string
      add :active_profile_user_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])

    create table(:identities) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :provider_token, :string, null: false
      add :provider_login, :string, null: false
      add :provider_email, :string, null: false
      add :provider_id, :string, null: false
      add :provider_meta, :map, default: "{}", null: false

      timestamps()
    end

    create index(:identities, [:user_id])
    create index(:identities, [:provider])
    create unique_index(:identities, [:user_id, :provider])
  end
end
