defmodule LiveBeatsWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](http://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence, otp_app: :live_beats,
                        pubsub_server: LiveBeats.PubSub

  import Phoenix.LiveView.Helpers
  import LiveBeatsWeb.LiveHelpers

  def listening_now(assigns) do
    ~H"""
    <!-- users -->
    <div class="px-4 mt-6 sm:px-6 lg:px-8">
      <h2 class="text-gray-500 text-xs font-medium uppercase tracking-wide">Who's Listening</h2>
      <ul role="list" class="grid grid-cols-1 gap-4 sm:gap-4 sm:grid-cols-2 xl:grid-cols-5 mt-3" x-max="1">
        <%= for presence <- @presences do %>
          <li class="relative col-span-1 flex shadow-sm rounded-md overflow-hidden">
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
end
