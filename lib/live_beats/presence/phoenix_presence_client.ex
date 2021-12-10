defmodule Phoenix.Presence.Client do
  use GenServer

  @doc """
  TODO

  ## Options

    * `:pubsub` - The required name of the pubsub server
    * `:presence` - The required name of the presence module
    * `:client` - The required callback module
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: PresenceClient)
  end

  def track(topic, key, meta) do
    GenServer.call(PresenceClient, {:track, self(), topic, to_string(key), meta})
  end

  def untrack(topic, key) do
    GenServer.call(PresenceClient, {:untrack, self(), topic, to_string(key)})
  end

  def init(opts) do
    client = Keyword.fetch!(opts, :client)
    client_state = client.init(%{})

    state = %{
      topics: %{},
      client: client,
      pubsub: Keyword.fetch!(opts, :pubsub),
      presence_mod: Keyword.fetch!(opts, :presence),
      client_state: client_state
    }

    {:ok, state}
  end

  def handle_info(%{topic: topic, event: "presence_diff", payload: diff}, state) do
    {:noreply, merge_diff(state, topic, diff)}
  end

  def handle_call(:state, _from, state) do
    IO.inspect(state.topics, label: :state_topics)
    {:reply, :ok, state}
  end

  def handle_call({:track, pid, topic, key, meta}, _from, state) do
    {:reply, :ok, track_pid(state, pid, topic, key, meta)}
  end

  def handle_call({:untrack, pid, topic, key}, _from, state) do
    {:reply, :ok, untrack_pid(state, pid, topic, key)}
  end

  defp track_pid(state, pid, topic, key, meta) do
    # presences are handled when the presence_diff event is received
    case Map.fetch(state.topics, topic) do
      {:ok, _topic_content} ->
        state.presence_mod.track(pid, topic, key, meta)
        state

      :error ->
        # subscribe to topic we weren't yet tracking
        Phoenix.PubSub.subscribe(state.pubsub, topic)
        state.presence_mod.track(pid, topic, key, meta)
        state
    end
  end

  defp untrack_pid(state, pid, topic, key) do
    if Map.has_key?(state.topics, topic) do
      state.presence_mod.untrack(pid, topic, key)
    else
      state
    end
  end

  defp merge_diff(state, topic, %{leaves: leaves, joins: joins}) do
    # add new topic if needed
    updated_state =
      if Map.has_key?(state.topics, topic) do
        state
      else
        update_topics_state(:add_new_topic, state, topic)
      end

    # merge diff into state.topics
    {updated_state, _topic} = Enum.reduce(joins, {updated_state, topic}, &handle_join/2)
    {updated_state, _topic} = Enum.reduce(leaves, {updated_state, topic}, &handle_leave/2)

    # if no more presences for given topic, unsubscribe and remove topic
    if topic_presences_count(updated_state, topic) == 0 do
      Phoenix.PubSub.unsubscribe(state.pubsub, topic)
      update_topics_state(:remove_topic, updated_state, topic)
    else
      updated_state
    end
  end

  defp handle_join({joined_key, meta}, {state, topic}) do
    joined_meta = Map.get(meta, :metas, [])
    updated_state = update_topics_state(:add_new_presence, state, topic, joined_key, joined_meta)
    state.client.handle_join(topic, joined_key, joined_meta, state)
    {updated_state, topic}
  end

  defp handle_leave({left_key, meta}, {state, topic}) do
    updated_state = update_topics_state(:remove_presence, state, topic, left_key)
    state.client.handle_leave(topic, left_key, meta, state)
    {updated_state, topic}
  end

  defp update_topics_state(:add_new_topic, %{topics: topics} = state, topic) do
    updated_topics = Map.put_new(topics, topic, %{})
    Map.put(state, :topics, updated_topics)
  end

  defp update_topics_state(:remove_topic, %{topics: topics} = state, topic) do
    updated_topics = Map.delete(topics, topic)
    Map.put(state, :topics, updated_topics)
  end

  defp update_topics_state(:add_new_presence, %{topics: topics} = state, topic, key, meta) do
    updated_topic =
      topics[topic]
      |> Map.put(key, meta)

    updated_topics = Map.put(topics, topic, updated_topic)

    Map.put(state, :topics, updated_topics)
  end

  defp update_topics_state(:remove_presence, %{topics: topics} = state, topic, key) do
    updated_presences =
      topics[topic]
      |> Map.delete(key)

    updated_topics = Map.put(topics, topic, updated_presences)

    Map.put(state, :topics, updated_topics)
  end

  defp topic_presences_count(state, topic) do
    state.topics[topic]
    |> Map.keys()
    |> Enum.count()
  end
end
