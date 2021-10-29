defmodule LiveBeatsWeb.Nav do
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  def on_mount(:default, _params, session, socket) do
    {:cont, assign(socket, genres: LiveBeats.MediaLibrary.list_genres())}
  end
end
