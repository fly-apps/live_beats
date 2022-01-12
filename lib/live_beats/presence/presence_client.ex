defmodule LiveBeats.PresenceClient do
  @behaviour Phoenix.Presence.Client

  @presence LiveBeatsWeb.Presence
  @pubsub LiveBeats.PubSub

  alias LiveBeats.MediaLibrary

  def track(%MediaLibrary.Profile{} = profile, current_user_id) do
    Phoenix.Presence.Client.track(
      "proxy:" <> topic(profile),
      current_user_id,
      %{}
    )
  end

  def untrack(%MediaLibrary.Profile{} = profile, current_user_id) do
    Phoenix.Presence.Client.untrack(
      "proxy:" <> topic(profile),
      current_user_id
    )
  end

  def subscribe(%MediaLibrary.Profile{} = profile) do
    Phoenix.PubSub.subscribe(@pubsub, topic(profile))
  end

  def list(%MediaLibrary.Profile{} = profile) do
    list("proxy:" <> topic(profile))
  end

  def list(topic) do
    @presence.list(topic)
  end

  @impl Phoenix.Presence.Client
  def init(_opts) do
    # user-land state
    {:ok, %{}}
  end

  @impl Phoenix.Presence.Client
  def handle_join(topic, _key, presence, state) do
    local_broadcast(topic, {__MODULE__, %{user_joined: presence}})
    {:ok, state}
  end

  @impl Phoenix.Presence.Client
  def handle_leave(topic, _key, presence, state) do
    local_broadcast(topic, {__MODULE__, %{user_left: presence}})
    {:ok, state}
  end

  defp topic(%MediaLibrary.Profile{} = profile) do
    "active_profiles:#{profile.user_id}"
  end

  defp local_broadcast("proxy:" <> topic, payload) do
    Phoenix.PubSub.local_broadcast(@pubsub, topic, payload)
  end
end
