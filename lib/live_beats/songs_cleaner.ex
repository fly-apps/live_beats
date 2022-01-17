defmodule LiveBeats.SongsCleaner do
  @moduledoc """
  Expire user songs using a polling interval.
  """
  use GenServer

  alias LiveBeats.MediaLibrary

  @poll_interval :timer.minutes(60)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    count = Keyword.fetch!(opts, :count)
    interval = Keyword.fetch!(opts, :interval)
    MediaLibrary.expire_songs_older_than(count, interval)

    {:ok, schedule_cleanup(%{count: count, interval: interval})}
  end

  @impl true
  def handle_info(:remove_songs, %{count: count, interval: interval} = state) do
    MediaLibrary.expire_songs_older_than(count, interval)
    {:noreply, schedule_cleanup(state)}
  end

  defp schedule_cleanup(state) do
    Process.send_after(self(), :remove_songs, @poll_interval)
    state
  end
end
