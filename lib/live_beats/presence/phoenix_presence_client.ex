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
    GenServer.call(PresenceClient, {:untrack, self(), to_string(topic), key})
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
    case Map.fetch(state.topics, topic) do
      {:ok, _topic_content} ->
        state.presence_mod.track(pid, topic, key, meta)
        update_topics_state(:add_new_presence, state, topic, key, meta)

      :error ->
        # subscribe to topic we weren't yet tracking
        Phoenix.PubSub.subscribe(state.pubsub, topic)
        state.presence_mod.track(pid, topic, key, meta)
        update_topics_state(:add_new_topic, state, topic, key, meta)
    end
  end

  defp untrack_pid(state, pid, topic, key) do
    state.presence_mod.untrack(pid, topic, key)
    # remove presence from state.topics
    if Map.has_key?(state.topics, topic) do
      presences_count =
        state.topics[topic]
        |> Map.keys()
        |> Enum.count()

      # if no more presences for given topic, unsubscribe
      if presences_count == 0 do
        Phoenix.PubSub.unsubscribe(state.pubsub, topic)
        update_topics_state(:remove_topic, state, topic, key)
      else
        update_topics_state(:remove_presence, state, topic, key)
      end
    else
      state
    end
  end

  # is a join
  defp merge_diff(state, topic, %{leaves: leaves, joins: joins}) when map_size(leaves) == 0 do
    # merge diff into state.topics
    joined_key = Map.keys(joins) |> hd
    joined_meta = joins[joined_key].metas |> hd

    state.client.handle_join(topic, joined_key, joined_meta, state)

    if Map.has_key?(state.topics, topic) do
      update_topics_state(:add_new_presence, state, topic, joined_key, joined_meta)
    else
      update_topics_state(:add_new_topic, state, topic, joined_key, joined_meta)
    end
  end

  defp merge_diff(state, topic, %{leaves: leaves, joins: joins}) when map_size(joins) == 0 do
    presences_count =
      state.topics[topic]
      |> Map.keys()
      |> Enum.count()

    left_key = Map.keys(leaves) |> hd
    left_meta = leaves[left_key].metas |> hd

    state.client.handle_leave(topic, left_key, left_meta, state)
    # if no more presences for given topic, unsubscribe
    if presences_count == 0 do
      Phoenix.PubSub.unsubscribe(state.pubsub, topic)
      update_topics_state(:remove_topic, state, topic, left_key)
    else
      update_topics_state(:remove_presence, state, topic, left_key)
    end
  end

  defp update_topics_state(:add_new_topic, %{topics: topics} = state, topic, key, meta) do
    topic_presences = %{key => meta}
    updated_topics = Map.put_new(topics, topic, topic_presences)
    Map.put(state, :topics, updated_topics)
  end

  defp update_topics_state(:add_new_presence, %{topics: topics} = state, topic, key, meta) do
    updated_topic =
      topics[topic]
      |> Map.put_new(key, meta)

    updated_topics = Map.put(topics, topic, updated_topic)

    Map.put(state, :topics, updated_topics)
  end

  defp update_topics_state(:remove_topic, %{topics: topics} = state, topic, _key) do
    updated_topics = Map.delete(topics, topic)
    Map.put(state, :topics, updated_topics)
  end

  defp update_topics_state(:remove_presence, %{topics: topics} = state, topic, key) do
    updated_presences =
      topics[topic]
      |> Map.delete(key)

    updated_topics = Map.put(topics, topic, updated_presences)

    Map.put(state, :topics, updated_topics)
  end
end
