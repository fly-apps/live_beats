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
    GenServer.call(PresenceClient, {:track, self(), topic, key, meta})
  end

  def untrack(topic, key) do
    GenServer.call(PresenceClient, {:untrack, self(), topic, key})
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

  def handle_call({:track, pid, topic, key, meta}, _from, state) do
    {:reply, :ok, track_pid(state, pid, topic, key, meta)}
  end

  def handle_call({:untrack, pid, topic, key}, _from, state) do
    {:reply, :ok, untrack_pid(state, pid, topic, key)}
  end

  defp track_pid(state, pid, topic, key, meta) do
    case Map.fetch(state.topics, topic) do
      {:ok, presences} ->
        state.presence_mod.track(pid, topic, key, meta)
        # update topics state...
        # new_state
        state

      :error ->
        # subscribe to topic we weren't yet tracking
        Phoenix.PubSub.subscribe(state.pubsub, topic)
        # new_state
        state
    end
  end

  defp untrack_pid(state, pid, topic, key) do
    state.presence_mod.untrack(pid, topic, key)
    # remove presence from state.topics
    # if no more presences for given topic, unsubscribe
    #   Phoenix.PubSub.unsubscribe(state.pubsub, topic)
    # new_state
    state
  end

  defp merge_diff(state, topic, diff) do
    # merge diff into state.topics
    # invoke state.client.handle_join|handle_leave
    # if no more presences for given topic, unsubscribe
    #   Phoenix.PubSub.unsubscribe(state.pubsub, topic)
    # new_state
    state
  end
end
