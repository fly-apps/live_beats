defmodule LiveBeats.UserTracker do

  require Logger
  use GenServer
  @pubsub LiveBeats.PubSub
  @poll_interval :timer.seconds(5)

  @doc """
  TODO
  """

  def subscribe() do
    Phoenix.PubSub.subscribe(@pubsub, topic())
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, schedule_updates(%{})}
  end

  @impl true
  def handle_call({:user_joined, user}, _from, state) do
    {:reply, :ok, handle_join(state, user) |> IO.inspect}
  end

  @impl true
  def handle_call({:user_left, user}, _from, state) do
    {:reply, :ok, handle_leave(state, user) |> IO.inspect}
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

  defp handle_join(state, user) do
    if Map.has_key?(state, user.id) do
      state
    else
      Map.put_new(state, user.id, user)
    end
  end

  defp handle_leave(state, user) do
    if Map.has_key?(state, user.id) do
      Map.delete(state, user.id)
    else
      state
    end
  end

  defp topic() do
    "active_users"
  end

  defp broadcast_updates(state) do
    active_users =
    state
    |> Enum.map(fn {_key, value} -> value end)

    Logger.info(
          "broadcasting updates"
        )
    Phoenix.PubSub.local_broadcast(@pubsub, topic(), active_users)
  end

end
