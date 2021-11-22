defmodule LiveBeatsWeb.Nav do
  import Phoenix.LiveView

  alias LiveBeats.MediaLibrary

  def on_mount(:default, params, _session, socket) do
    active_tab =
      case params do
      %{"profile_username" => _profile} -> :index
      _ -> :settings
    end

    {:cont, assign(socket, [active_users: MediaLibrary.list_active_profiles(limit: 20), active_tab: active_tab])}
  end
end
