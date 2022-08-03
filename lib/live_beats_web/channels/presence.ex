defmodule LiveBeatsWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](http://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :live_beats,
    pubsub_server: LiveBeats.PubSub,
    presence: __MODULE__

  @pubsub LiveBeats.PubSub

  import Phoenix.LiveView.Helpers
  import LiveBeatsWeb.LiveHelpers

  alias LiveBeats.{Accounts, MediaLibrary}
  alias LiveBeatsWeb.Presence.BadgeComponent

  def track_profile_user(%MediaLibrary.Profile{} = profile, current_user_id) do
    track(
      self(),
      "proxy:" <> topic(profile),
      current_user_id,
      %{}
    )
  end

  def untrack_profile_user(%MediaLibrary.Profile{} = profile, current_user_id) do
    untrack(
      self(),
      "proxy:" <> topic(profile),
      current_user_id
    )
  end

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    for {user_id, presence} <- joins do
      user_data = %{user: presence.user, metas: Map.fetch!(presences, user_id)}
      local_broadcast(topic, {__MODULE__, %{user_joined: user_data}})
    end

    for {user_id, presence} <- leaves do
      metas =
        case Map.fetch(presences, user_id) do
          {:ok, presence_metas} -> presence_metas
          :error -> []
        end

      user_data = %{user: presence.user, metas: metas}

      local_broadcast(topic, {__MODULE__, %{user_left: user_data}})
    end

    {:ok, state}
  end

  def list_profile_users(%MediaLibrary.Profile{} = profile) do
    list("proxy:" <> topic(profile))
  end

  def subscribe(%MediaLibrary.Profile{} = profile) do
    Phoenix.PubSub.subscribe(@pubsub, topic(profile))
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

  def listening_now(assigns) do
    import Phoenix.LiveView
    count = Enum.count(assigns.presence_ids)

    assigns =
      assigns
      |> assign(:count, count)
      |> assign_new(:total_count, fn -> count end)

    ~H"""
    <div class="px-4 mt-6 sm:px-6 lg:px-8">
      <!-- users -->
      <h2 class="text-gray-500 text-xs font-medium uppercase tracking-wide">
        Listening now (<%= @count %>)
      </h2>
      <ul
        id="listening-now"
        role="list"
        x-max="1"
        class="grid grid-cols-1 gap-4 sm:gap-4 sm:grid-cols-2 xl:grid-cols-5 mt-3"
      >
        <%= for {id, _time} <- Enum.sort(@presence_ids, fn {_, t1}, {_, t2} -> t1 < t2 end) do %>
          <.live_component id={id} module={BadgeComponent} presence={@presences[id]} />
        <% end %>
      </ul>
      <%= if @total_count > @count do %>
        <p>+ <%= @total_count - @count %> more</p>
      <% end %>
    </div>
    """
  end

  defp local_broadcast("proxy:" <> topic, payload) do
    Phoenix.PubSub.local_broadcast(@pubsub, topic, payload)
  end

  defp topic(%MediaLibrary.Profile{} = profile) do
    "active_profiles:#{profile.user_id}"
  end
end

defmodule LiveBeatsWeb.Presence.BadgeComponent do
  use LiveBeatsWeb, :live_component

  #  https://fly.io/docs/reference/regions/
  @region_names %{
    "ams" => "Amsterdam, Netherlands",
    "atl" => "Atlanta, Georgia (US)",
    "cdg" => "Paris, France",
    "dfw" => "Dallas, Texas (US)",
    "ewr" => "Parsippany, NJ (US)",
    "fra" => "Frankfurt, Germany",
    "gru" => "Sao Paulo, Brazil",
    "hkg" => "Hong Kong",
    "iad" => "Ashburn, Virginia (US)",
    "lax" => "Los Angeles, California (US)",
    "lhr" => "London, United Kingdom",
    "maa" => "Chennai (Madras), India",
    "nrt" => "Tokyo, Japan",
    "ord" => "Chicago, Illinois (US)",
    "scl" => "Santiago, Chile",
    "sea" => "Seattle, Washington (US)",
    "sin" => "Singapore",
    "sjc" => "Sunnyvale, California (US)",
    "syd" => "Sydney, Australia",
    "yyz" => "Toronto, Canada"
  }

  def render(assigns) do
    ~H"""
    <li id={"presence-#{@id}"} class="relative col-span-1 flex shadow-sm rounded-md overflow-hidden">
      <.link
        navigate={profile_path(@presence)}
        class="flex-1 flex items-center justify-between border-t border-r border-b border-gray-200 bg-white rounded-r-md truncate"
      >
        <img
          class="w-12 h-12 flex-shrink-0 flex items-center justify-center rounded-l-md bg-purple-600"
          src={@presence.avatar_url}
          alt=""
        />
        <div class="flex-1 flex items-center justify-between text-gray-900 text-sm font-medium hover:text-gray-600 pl-3">
          <div class="flex-1 py-1 text-sm truncate">
            <%= @presence.username %>
            <%= if @ping do %>
              <p class="text-gray-400 text-xs">ping: <%= @ping %>ms</p>
              <%= if @region do %>
                <img
                  class="inline w-7 h-7 absolute right-3 top-3"
                  src={"https://fly.io/ui/images/#{@region}.svg"}
                  title={region_name(@region)}
                />
              <% end %>
            <% end %>
          </div>
        </div>
      </.link>
    </li>
    """
  end

  def mount(socket) do
    {:ok, socket, temporary_assigns: [presence: nil, ping: nil, region: nil]}
  end

  def update(%{action: {:ping, action}}, socket) do
    %{user: user, ping: ping, region: region} = action
    now = now_ms()

    # debounce other tabs sending valid ping frequency
    if now - socket.assigns.last_ping_at > 1000 do
      {:ok, assign(socket, presence: user, ping: ping, region: region, last_ping_at: now)}
    else
      {:ok, socket}
    end
  end

  def update(%{presence: nil}, socket), do: {:ok, socket}

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id, presence: assigns.presence)
     |> assign_new(:pings, fn -> %{} end)
     |> assign_new(:regions, fn -> %{} end)
     |> assign_new(:last_ping_at, fn -> now_ms() end)}
  end

  defp now_ms, do: System.system_time(:millisecond)

  defp region_name(region), do: Map.get(@region_names, region)
end
