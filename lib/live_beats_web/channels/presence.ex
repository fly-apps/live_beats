defmodule LiveBeatsWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](http://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :live_beats,
    pubsub_server: LiveBeats.PubSub

  import Phoenix.LiveView.Helpers
  import LiveBeatsWeb.LiveHelpers
  @pubsub LiveBeats.PubSub

  alias LiveBeats.Accounts

  def listening_now(assigns) do
    ~H"""
    <!-- users -->
    <div class="px-4 mt-6 sm:px-6 lg:px-8">
      <h2 class="text-gray-500 text-xs font-medium uppercase tracking-wide">Here now</h2>
      <ul
        id="listening-now"
        phx-update="prepend"
        role="list"
        x-max="1"
        class="grid grid-cols-1 gap-4 sm:gap-4 sm:grid-cols-2 xl:grid-cols-5 mt-3"
      >
        <%= for presence <- @presences do %>
          <li id={"presence-#{presence.id}"} class="relative col-span-1 flex shadow-sm rounded-md overflow-hidden">
            <.link navigate={profile_path(presence)} class="flex-1 flex items-center justify-between border-t border-r border-b border-gray-200 bg-white rounded-r-md truncate">
              <img class="w-10 h-10 flex-shrink-0 flex items-center justify-center rounded-l-md bg-purple-600" src={presence.avatar_url} alt="">
              <div class="flex-1 flex items-center justify-between text-gray-900 text-sm font-medium hover:text-gray-600 pl-3">
                <%= render_slot(@title, presence) %>
              </div>
            </.link>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  def fetch(_topic, presences) do
    users =
      presences
      |> Map.keys()
      |> Accounts.get_users_map()
      |> Enum.into(%{})

    for {key, %{metas: metas}} <- presences, into: %{} do
      {key, %{metas: metas, user: users[String.to_integer(key)]}}
    end
  end

  def subscribe(user_id) do
    Phoenix.PubSub.subscribe(@pubsub, topic(user_id))
  end

  defp topic(profile) do
    "active_users:#{profile.user_id}"
  end
end
