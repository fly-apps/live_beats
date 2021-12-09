defmodule LiveBeats.PresenceClient do
  @behaviour Phoenix.Presence.Client

  @presence LiveBeats.Presence

  def start_link(opts) do
    Phoenix.Presence.Client.start_link(presence: @presence, client: __MODULE__)
  end

  def list(topic) do
    @presence.list(topic)
  end

  def init(_opts) do
    # user-land state
    {:ok, %{}}
  end

  def handle_join(key, presence, state) do
    # can local pubsub to LVs about new join
    {:ok, state}
  end

  def handle_leave(key, presence, state) do
    # can local pubsub to LVs about new leave
    {:ok, state}
  end
end
