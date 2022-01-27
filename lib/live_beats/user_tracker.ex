defmodule LiveBeats.UserTracker do
  @moduledoc """
    Send active users updates using a polling interval.
  """

  use GenServer
  @pubsub LiveBeats.PubSub
  @poll_interval :timer.seconds(30)

  def subscribe() do
    Phoenix.PubSub.subscribe(@pubsub, topic())
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def list_active_users() do
    GenServer.call(__MODULE__, :list_users)
  end

  def presence_joined(presence) do
    GenServer.call(__MODULE__, {:presence_joined, presence})
  end

  def presence_left(presence) do
    GenServer.call(__MODULE__, {:presence_left, presence})
  end

  @impl true
  def init(_opts) do
    {:ok, schedule_updates(%{})}
  end

  @impl true
  def handle_call(:list_users, _from, state) do
    {:reply, list_users(state), state}
  end

  @impl true
  def handle_call({:presence_joined, presence}, _from, state) do
    {:reply, :ok, handle_join(state, presence)}
  end

  @impl true
  def handle_call({:presence_left, presence}, _from, state) do
    {:reply, :ok, handle_leave(state, presence)}
  end

  @impl true
  def handle_info(:send_updates, state) do
    broadcast_updates(state)
    {:noreply, schedule_updates(state)}
  end

  defp schedule_updates(state) do
    Process.send_after(self(), :send_updates, @poll_interval)
    state
  end

  defp handle_join(state, presence) do
    if Map.has_key?(state, presence.user.id) do
      state
    else
      Map.put_new(state, presence.user.id, presence.user)
    end
  end

  defp handle_leave(state, presence) do
    if Map.has_key?(state, presence.user.id) and presence.metas == [] do
      Map.delete(state, presence.user.id)
    else
      state
    end
  end

  defp topic() do
    "active_users"
  end

  defp broadcast_updates(state) do
    Phoenix.PubSub.local_broadcast(
      @pubsub,
      topic(),
      {LiveBeats.UserTracker, %{active_users: list_users(state)}}
    )
  end

  defp list_users(state) do
    Enum.map(state, fn {_key, value} -> value end)
  end
end
