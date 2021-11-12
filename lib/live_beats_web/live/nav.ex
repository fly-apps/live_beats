defmodule LiveBeatsWeb.Nav do
  import Phoenix.LiveView

  alias LiveBeats.MediaLibrary

  def on_mount(:default, _params, _session, socket) do
    {:cont, assign(socket, :active_users, MediaLibrary.list_active_profiles(limit: 20))}
  end
end
