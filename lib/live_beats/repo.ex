defmodule LiveBeats.Repo do
  use Ecto.Repo,
    otp_app: :live_beats,
    adapter: Ecto.Adapters.Postgres

  @locks %{playlist: 1}

  def multi_transaction_lock(multi, scope, id) when is_atom(scope) and is_integer(id) do
    scope_int = Map.fetch!(@locks, scope)

    Ecto.Multi.run(multi, scope, fn repo, _changes ->
      repo.query("SELECT pg_advisory_xact_lock(#{scope_int}, #{id})")
    end)
  end
end
