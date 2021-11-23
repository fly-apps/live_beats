defmodule LiveBeatsWeb.Nav do
  import Phoenix.LiveView

  alias LiveBeats.MediaLibrary
  alias LiveBeatsWeb.{ProfileLive, SettingsLive}

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign(active_users: MediaLibrary.list_active_profiles(limit: 20))
     |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)}
  end

  defp handle_active_tab_params(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {ProfileLive, _} -> :profile
        {SettingsLive, _} -> :settings
        {_, _} -> nil
      end

    {:cont, assign(socket, active_tab: active_tab)}
  end
end
