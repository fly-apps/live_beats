defmodule LiveBeatsWeb.Nav do
  import Phoenix.LiveView
  use Phoenix.Component

  alias LiveBeats.{Accounts, MediaLibrary}
  alias LiveBeatsWeb.{ProfileLive, SettingsLive}

  def on_mount(:default, _params, _session, socket) do
    if connected?(socket) do
      MediaLibrary.subscribe_to_active_profiles()
    end

    active_users = MediaLibrary.list_active_profiles(limit: 20)

    {:cont,
     socket
     |> stream_configure(:mobile_active_users, dom_id: &"mobile_active-#{&1.user_id}")
     |> stream_configure(:active_users, dom_id: &"active-#{&1.user_id}")
     |> stream(:active_users, active_users)
     |> stream(:mobile_active_users, active_users)
     |> assign(:region, System.get_env("FLY_REGION") || "iad")
     |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)
     |> attach_hook(:ping, :handle_event, &handle_event/3)
     |> attach_hook(:active_profile_changes, :handle_info, &handle_info/2)}
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

  defp handle_info({MediaLibrary, %MediaLibrary.Events.PublicProfileActive{} = update}, socket) do
    {:halt, stream_insert(socket, :active_users, update.profile)}
  end

  defp handle_info({MediaLibrary, %MediaLibrary.Events.PublicProfileInActive{} = update}, socket) do
    {:halt, stream_delete(socket, :active_users, update.profile)}
  end

  defp handle_info(_, socket), do: {:cont, socket}

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
