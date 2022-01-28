defmodule LiveBeats.Repo do
  use Ecto.Repo,
    otp_app: :live_beats,
    adapter: Ecto.Adapters.Postgres

  def replica, do: LiveBeats.config([:replica])
end

defmodule LiveBeats.ReplicaRepo do
  use Ecto.Repo,
    otp_app: :live_beats,
    adapter: Ecto.Adapters.Postgres
end
