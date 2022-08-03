defmodule Phoenix.Presence.Client.Mock do
  def init(_opts) do
    {:ok, %{}}
  end

  def handle_join(_topic, _key, _meta, state) do
    {:ok, state}
  end

  def handle_leave(_topic, _key, _meta, state) do
    {:ok, state}
  end
end
