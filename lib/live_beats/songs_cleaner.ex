defmodule LiveBeats.SongsCleaner do
  @moduledoc """
  Expire user songs using a polling interval.
  """
  use GenServer

  alias LiveBeats.MediaLibrary

  @poll_interval :timer.minutes(30)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    region = System.get_env("FLY_REGION")
    primary_region = System.get_env("PRIMARY_REGION")

    case region do
      region when region in [nil, primary_region] ->
        {count, interval} = Keyword.fetch!(opts, :interval)
        {:ok, schedule_cleanup(%{count: count, interval: interval}, 0)}

      _ ->
        :ignore
    end
  end

  @impl true
  def handle_info(:remove_songs, %{count: count, interval: interval} = state) do
    MediaLibrary.expire_songs_older_than(count, interval)
    {:noreply, schedule_cleanup(state)}
  end

  defp schedule_cleanup(state, after_ms \\ @poll_interval) do
    Process.send_after(self(), :remove_songs, after_ms)
    state
  end
end
