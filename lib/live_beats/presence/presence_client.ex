defmodule LiveBeats.PresenceClient do
  @behaviour Phoenix.Presence.Client

  @presence LiveBeatsWeb.Presence
  @pubsub LiveBeats.PubSub

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

  def handle_join(topic, key, _meta, state) do
    active_users_topic =
      topic
      |> profile_identifier()
      |> active_users_topic()

    Phoenix.PubSub.local_broadcast(@pubsub, active_users_topic, {__MODULE__, %{user_joined: key}})

    {:ok, state}
  end

  def handle_leave(topic, key, _meta, state) do
    active_users_topic =
      topic
      |> profile_identifier()
      |> active_users_topic()

    Phoenix.PubSub.local_broadcast(@pubsub, active_users_topic, {__MODULE__, %{user_left: key}})
    {:ok, state}
  end

  defp active_users_topic(user_id) do
    "active_users:#{user_id}"
  end

  defp profile_identifier(topic) do
    "active_profile:" <> identifier = topic
    identifier
  end
end
