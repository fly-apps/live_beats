defmodule LiveBeatsWeb.Nav do
  import Phoenix.LiveView
  alias LiveBeats.UserTracker
  alias LiveBeatsWeb.{ProfileLive, SettingsLive}

  def on_mount(:default, _params, _session, socket) do
    if connected?(socket) do
      UserTracker.subscribe()
    end

    socket =
    socket
    |> assign(:active_users, UserTracker.list_active_users())
    |> assign(:region, System.get_env("FLY_REGION"))
    |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)
    |> attach_hook(:ping, :handle_event, &handle_event/3)
    |> attach_hook(:active_users, :handle_info, &handle_info/2)

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

  defp handle_info({UserTracker, %{user_leaves: leaves, user_joins: joins}}, socket) do
    updated_socket =
      Enum.reduce(leaves, socket, fn user, socket ->
        socket
        |> push_event("remove-el", %{id: "mobile-active-users-container-#{user.id}"})
        |> push_event("remove-el", %{id: "desktop-active-users-container-#{user.id}"})
      end)

    {:halt, update(updated_socket, :active_users, &(joins ++ &1))}
  end

  defp handle_info(_params, socket), do: {:cont, socket}

  defp current_user_profile_username(socket) do
    if user = socket.assigns.current_user do
      user.username
    end
  end
end
