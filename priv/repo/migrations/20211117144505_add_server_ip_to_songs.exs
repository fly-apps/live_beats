defmodule LiveBeats.Repo.Migrations.AddServerIpToSongs do
  use Ecto.Migration

  def change do
    alter table(:songs) do
      add :server_ip, :string
    end
  end
end
