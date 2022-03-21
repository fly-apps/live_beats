defmodule LiveBeats.PresenceClient do

  @presence LiveBeatsWeb.Presence
  @pubsub LiveBeats.PubSub

  alias LiveBeats.MediaLibrary

  def track(%MediaLibrary.Profile{} = profile, current_user_id) do
    @presence.track(
      self(),
      "proxy:" <> topic(profile),
      current_user_id,
      %{}
    )
  end

  def untrack(%MediaLibrary.Profile{} = profile, current_user_id) do
    @presence.untrack(
      self(),
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

  def init(_opts) do
    # user-land state
    {:ok, %{}}
  end

  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    for {user_id, presence} <- joins do
      user_data = %{user: presence.user, metas: Map.fetch!(presences, user_id)}
      local_broadcast(topic, {LiveBeats.PresenceClient, %{user_joined: user_data}})
    end

    for {user_id, presence} <- leaves do
      metas =
      case Map.fetch(presences, user_id) do
        {:ok, presence_metas} -> presence_metas
        :error -> []
      end

      user_data = %{user: presence.user, metas: metas}

      local_broadcast(topic, {LiveBeats.PresenceClient, %{user_left: user_data}})
    end

    {:ok, state}
  end

  defp topic(%MediaLibrary.Profile{} = profile) do
    "active_profiles:#{profile.user_id}"
  end

  defp local_broadcast("proxy:" <> topic, payload) do
    Phoenix.PubSub.local_broadcast(@pubsub, topic, payload)
  end
end
