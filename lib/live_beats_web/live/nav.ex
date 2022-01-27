defmodule LiveBeatsWeb.Nav do
  import Phoenix.LiveView
  alias LiveBeats.UserTracker
  alias LiveBeatsWeb.{ProfileLive, SettingsLive}

  def on_mount(:default, _params, _session, socket) do
    if connected?(socket) do
      UserTracker.subscribe()
    end

    socket
    |> assign(:active_users, UserTracker.list_active_users())
    |> assign(:region, System.get_env("FLY_REGION"))
    |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)
    |> attach_hook(:ping, :handle_event, &handle_event/3)
    |> attach_hook(:actie_users, :handle_info, fn
      {LiveBeats.UserTracker, %{active_users: users}}, socket ->
      {:halt, assign(socket, :active_users, users)}

    _params, socket ->
      {:cont, socket}

    end)

    {:cont, socket}
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

  defp handle_event("ping", _, socket) do
    {:halt, push_event(socket, "pong", %{})}
  end

  defp handle_event(_, _, socket), do: {:cont, socket}

  defp current_user_profile_username(socket) do
    if user = socket.assigns.current_user do
      user.username
    end
  end
end
