defmodule LiveBeatsWeb.SongLive.SongRow do
  use LiveBeatsWeb, :live_component

  def render(assigns) do
    ~H"""
    <tr id={@id} class={@class}}>
      <%= for {col, i} <- Enum.with_index(@col) do %>
        <td
          class={"px-6 py-3 whitespace-nowrap text-sm font-medium text-gray-900 #{if i == 0, do: "max-w-0 w-full cursor-pointer"}"}
          phx-click={JS.push("play-song", value: %{id: @song.id})}
         >
          <div class="flex items-center space-x-3 lg:pl-2">
              <%= if i == 0 do %>
                <%= if @active do %>
                  <span class="flex pt-1 relative mr-2 w-4">
                    <span class="w-3 h-3 animate-ping bg-purple-400 rounded-full absolute"></span>
                    <.icon name={:volume_up} class="h-5 w-5 -mt-1 -ml-1"/>
                  </span>
                <% else %>
                  <span class="flex relative w-6 -translate-x-1">
                    <.icon name={:play} class="h-5 w-5 text-gray-400"/>
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

  def update(%{action: :activate}, socket) do
    {:ok, assign(socket, active: true)}
  end

  def update(%{action: :deactivate}, socket) do
    {:ok, assign(socket, active: false)}
  end

  def update(%{action: action}, _socket) do
    raise ArgumentError, "unkown action #{inspect(action)}"
  end

  def update(assigns, socket) do
    {:ok,
     assign(socket,
       id: assigns.id,
       song: assigns.row,
       col: assigns.col,
       class: assigns.class,
       index: assigns.index,
       active: false
     )}
  end
end
