defmodule LiveBeats.Repo.Migrations.AddServerIpToSongs do
  use Ecto.Migration

  def change do
    alter table(:songs) do
      add :server_ip, :inet
    end
  end
end
