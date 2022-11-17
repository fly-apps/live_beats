defmodule LiveBeatsWeb.Nav do
  import Phoenix.LiveView
  use Phoenix.Component

  alias LiveBeats.{Accounts, MediaLibrary}
  alias LiveBeatsWeb.{ProfileLive, SettingsLive}

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign(active_users: MediaLibrary.list_active_profiles(limit: 20))
     |> assign(:region, System.get_env("FLY_REGION") || "iad")
     |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)
     |> attach_hook(:ping, :handle_event, &handle_event/3)}
  end

  defp handle_active_tab_params(params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {ProfileLive, _} ->
          if params["profile_username"] == current_user_profile_username(socket) do
            :profile
          end

        {SettingsLive, _} ->
          :settings

        {_, _} ->
          nil
      end

    {:cont, assign(socket, active_tab: active_tab)}
  end

  defp handle_event("ping", %{"rtt" => rtt}, socket) do
    {:halt,
     socket
     |> rate_limited_ping_broadcast(socket.assigns.current_user, rtt)
     |> push_event("pong", %{})}
  end

  defp handle_event(_, _, socket), do: {:cont, socket}

  defp rate_limited_ping_broadcast(socket, %Accounts.User{} = user, rtt) when is_integer(rtt) do
    now = System.system_time(:millisecond)
    last_ping_at = socket.assigns[:last_ping_at]

    if is_nil(last_ping_at) || now - last_ping_at > 1000 do
      MediaLibrary.broadcast_ping(user, rtt, socket.assigns.region)
      assign(socket, :last_ping_at, now)
    else
      socket
    end
  end

  defp rate_limited_ping_broadcast(socket, _user, _rtt), do: socket

  defp current_user_profile_username(socket) do
    if user = socket.assigns.current_user do
      user.username
    end
  end
end
