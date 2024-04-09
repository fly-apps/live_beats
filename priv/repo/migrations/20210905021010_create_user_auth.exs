defmodule LiveBeats.Repo.Migrations.CreateUserAuth do
  use Ecto.Migration
  import Ecto.Query

  def change do
    # email_type =
    #   if repo().exists?(
    #        from(e in "pg_available_extensions", where: e.name == "citext", select: e.name)
    #      ) do
    #     execute "CREATE EXTENSION IF NOT EXISTS citext", ""
    #     :citext
    #   else
    #     :string
    #   end

    create table(:users) do
      add :email, :string, null: false
      add :username, :string, null: false
      add :name, :string
      add :role, :string, null: false
      add :confirmed_at, :naive_datetime
      add :profile_tagline, :string
      add :active_profile_user_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:users, ["lower(email)"], name: :users_email_index)
    create unique_index(:users, ["lower(username)"], name: :users_username_index)

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
