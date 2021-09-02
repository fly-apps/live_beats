defmodule LiveBeats.Repo do
  use Ecto.Repo,
    otp_app: :live_beats,
    adapter: Ecto.Adapters.Postgres
end
