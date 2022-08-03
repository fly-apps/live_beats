defmodule LiveBeatsWeb.ProfileLive.SongRowComponent do
  use LiveBeatsWeb, :live_component

  def send_status(song_id, status) when status in [:playing, :paused, :stopped] do
    send_update(__MODULE__, id: "song-#{song_id}", action: :send, status: status)
  end

  def render(assigns) do
    ~H"""
    <tr id={@id} class={@class} tabindex="0">
      <%= for {col, i} <- Enum.with_index(@col) do %>
        <td
          class={
            "px-6 py-3 text-sm font-medium text-gray-900 #{if i == 0, do: "w-80 cursor-pointer"} #{col[:class]}"
          }
          phx-click={JS.push("play_or_pause", value: %{id: @song.id})}
        >
          <div class="flex items-center space-x-3 lg:pl-2">
            <%= if i == 0 do %>
              <%= if @status == :playing do %>
                <span class="flex pt-1 relative mr-2 w-4">
                  <span class="w-3 h-3 animate-ping bg-purple-400 rounded-full absolute"></span>
                  <.icon
                    name={:volume_up}
                    class="h-5 w-5 -mt-1 -ml-1"
                    aria-label="Playing"
                    role="button"
                  />
                </span>
              <% end %>
              <%= if @status == :paused do %>
                <span class="flex pt-1 relative mr-2 w-4">
                  <.icon
                    name={:volume_up}
                    class="h-5 w-5 -mt-1 -ml-1 text-gray-400"
                    aria-label="Paused"
                    role="button"
                  />
                </span>
              <% end %>
              <%= if @status == :stopped do %>
                <span class="flex relative w-6 -translate-x-1">
                  <%= if @owns_profile? do %>
                    <.icon name={:play} class="h-5 w-5 text-gray-400" aria-label="Play" role="button" />
                  <% end %>
                </span>
              <% end %>
            <% end %>
            <%= render_slot(col, assigns) %>
          </div>
        </td>
      <% end %>
    </tr>
    """
  end

  def update(%{action: :send, status: status}, socket)
      when status in [:playing, :paused, :stopped] do
    {:ok, assign(socket, status: status)}
  end

  def update(assigns, socket) do
    {:ok,
     assign(socket,
       id: assigns.id,
       song: assigns.row,
       col: assigns.col,
       class: assigns.class,
       index: assigns.index,
       status: :stopped,
       owns_profile?: assigns.owns_profile?
     )}
  end
end
