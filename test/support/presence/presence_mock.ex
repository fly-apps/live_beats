defmodule Phoenix.Presence.Client.PresenceMock do
  use GenServer
  alias Phoenix.Presence.Client

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts[:id], opts)
  end

  @impl true
  def init(id) do
    {:ok, %{id: id}}
  end

  def track(client_pid, pid, topic, key, meta \\ %{}) do
    GenServer.cast(pid, {:track, client_pid, topic, key, meta})
  end

  @impl true
  def handle_info(:quit, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({:track, client_pid, topic, key, meta}, state) do
    Client.track(client_pid, topic, key, meta)
    {:noreply, state}
  end
end
