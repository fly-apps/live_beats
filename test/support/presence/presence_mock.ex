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

  def track(pid, topic, key) do
    GenServer.cast(pid, {:track, topic, key})
  end

  @impl true
  def handle_info(:quit, state) do
    IO.inspect(:quit)
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({:track, topic, key}, state) do
    Client.track(topic, key, %{})
    {:noreply, state}
  end
end
