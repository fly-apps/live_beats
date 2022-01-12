defmodule Phoenix.Presence.Client do
  use GenServer

  @callback init(state :: term) :: {:ok, new_state :: term}
  @callback handle_join(topic :: String.t(), key :: String.t(), meta :: [map()], state :: term) ::
              {:ok, term}
  @callback handle_leave(topic :: String.t(), key :: String.t(), meta :: [map()], state :: term) ::
              {:ok, term}

  @doc """
  TODO

  ## Options

    * `:pubsub` - The required name of the pubsub server
    * `:presence` - The required name of the presence module
    * `:client` - The required callback module
  """
  def start_link(opts) do
    case Keyword.fetch(opts, :name) do
      {:ok, name} ->
        GenServer.start_link(__MODULE__, opts, name: name)

      :error ->
        GenServer.start_link(__MODULE__, opts)
    end
  end

  def track(pid \\ PresenceClient, topic, key, meta) do
    GenServer.call(pid, {:track, self(), topic, to_string(key), meta})
  end

  def untrack(pid \\ PresenceClient, topic, key) do
    GenServer.call(pid, {:untrack, self(), topic, to_string(key)})
  end

  def init(opts) do
    client = Keyword.fetch!(opts, :client)
    {:ok, client_state} = client.init(%{})

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
    {:reply, state, state}
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
    end

    state
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

    updated_state =
      update_topics_state(:add_new_presence_or_metas, state, topic, joined_key, joined_meta)

    {:ok, updated_client_state} =
      state.client.handle_join(topic, joined_key, meta, state.client_state)

    updated_state = Map.put(updated_state, :client_state, updated_client_state)

    {updated_state, topic}
  end

  defp handle_leave({left_key, meta}, {state, topic}) do
    updated_state = update_topics_state(:remove_presence_or_metas, state, topic, left_key, meta)

    {:ok, updated_client_state} =
      state.client.handle_leave(topic, left_key, meta, state.client_state)

    updated_state = Map.put(updated_state, :client_state, updated_client_state)

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

  defp update_topics_state(
         :add_new_presence_or_metas,
         %{topics: topics} = state,
         topic,
         key,
         new_metas
       ) do
    topic_info = topics[topic]

    updated_topic =
      case Map.fetch(topic_info, key) do
        # existing presence, add new metas
        {:ok, existing_metas} ->
          remaining_metas = new_metas -- existing_metas
          updated_metas = existing_metas ++ remaining_metas
          Map.put(topic_info, key, updated_metas)

        :error ->
          # there are no presences for that key
          Map.put(topic_info, key, new_metas)
      end

    updated_topics = Map.put(topics, topic, updated_topic)

    Map.put(state, :topics, updated_topics)
  end

  defp update_topics_state(
         :remove_presence_or_metas,
         %{topics: topics} = state,
         topic,
         key,
         deleted_metas
       ) do
    topic_info = topics[topic]

    state_metas = Map.get(topic_info, key, [])
    remaining_metas = state_metas -- Map.get(deleted_metas, :metas, [])

    updated_topic =
      case remaining_metas do
        # delete presence
        [] -> Map.delete(topic_info, key)
        # delete metas
        _ -> Map.put(topic_info, key, remaining_metas)
      end

    updated_topics = Map.put(topics, topic, updated_topic)

    Map.put(state, :topics, updated_topics)
  end

  defp topic_presences_count(state, topic) do
    map_size(state.topics[topic])
  end
end
