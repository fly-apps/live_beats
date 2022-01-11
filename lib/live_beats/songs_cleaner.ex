defmodule LiveBeats.SongsCleaner do
  @moduledoc """
  Remove user songs that were added ... ago
  """

  alias LiveBeats.MediaLibrary
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    schedule_cleanup()

    count = Keyword.fetch!(opts, :count)
    interval = Keyword.fetch!(opts, :interval)
    MediaLibrary.delete_expired_songs(count, interval)

    {:ok, %{count: count, interval: interval}}
  end

  @impl true
  def handle_info(:remove_songs, %{count: count, interval: interval} = state) do
    MediaLibrary.delete_expired_songs(count, interval)
    schedule_cleanup()

    {:noreply, state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :remove_songs, :timer.hours(3))
  end
end
