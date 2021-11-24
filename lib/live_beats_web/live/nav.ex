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

  defp handle_active_tab_params(params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {ProfileLive, _} ->
          if params["profile_username"] == current_user_profile_userame(socket) do
            :profile
          end

        {SettingsLive, _} ->
          :settings

        {_, _} ->
          nil
      end

    {:cont, assign(socket, active_tab: active_tab)}
  end

  defp current_user_profile_userame(socket) do
    if user = socket.assigns.current_user do
      user.username
    end
  end
end
