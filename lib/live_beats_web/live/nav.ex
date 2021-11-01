defmodule LiveBeatsWeb.Nav do
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    {:cont, assign(socket, genres: LiveBeats.MediaLibrary.list_genres())}
  end
end
