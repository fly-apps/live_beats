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
    {:ok,
     schedule_updates(%{
       active_users: %{},
       user_leaves: [],
       user_joins: []
     })}
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
    leaves = state.user_leaves -- state.user_joins
    joins = state.user_joins -- state.user_leaves

    broadcast_updates(leaves, joins)

    # cleaning joins and leaves for each interval
    new_state = %{state | user_leaves: [], user_joins: []}
    {:noreply, schedule_updates(new_state)}
  end

  defp schedule_updates(state) do
    Process.send_after(self(), :send_updates, @poll_interval)
    state
  end

  defp handle_join(state, %{user: user}) do
    if Map.has_key?(state.active_users, user.id) do
      state
    else
      updated_active_users = Map.put_new(state.active_users, user.id, user)
      updated_user_joins = [user | state.user_joins]

      %{state | active_users: updated_active_users, user_joins: updated_user_joins}
    end
  end

  defp handle_leave(state, %{user: user, metas: metas}) do
    if Map.has_key?(state.active_users, user.id) and metas == [] do
      updated_active_users = Map.delete(state.active_users, user.id)
      updated_user_leaves = [user | state.user_leaves]

      %{state | active_users: updated_active_users, user_leaves: updated_user_leaves}
    else
      state
    end
  end

  defp topic() do
    "active_users"
  end

  defp broadcast_updates(leaves, joins) do
    Phoenix.PubSub.local_broadcast(
      @pubsub,
      topic(),
      {LiveBeats.UserTracker, %{user_leaves: leaves, user_joins: joins}}
    )
  end

  defp list_users(state) do
    Enum.map(state.active_users, fn {_key, value} -> value end)
  end
end
