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
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 -mt-1 -ml-1" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M9.383 3.076A1 1 0 0110 4v12a1 1 0 01-1.707.707L4.586 13H2a1 1 0 01-1-1V8a1 1 0 011-1h2.586l3.707-3.707a1 1 0 011.09-.217zM14.657 2.929a1 1 0 011.414 0A9.972 9.972 0 0119 10a9.972 9.972 0 01-2.929 7.071 1 1 0 01-1.414-1.414A7.971 7.971 0 0017 10c0-2.21-.894-4.208-2.343-5.657a1 1 0 010-1.414zm-2.829 2.828a1 1 0 011.415 0A5.983 5.983 0 0115 10a5.984 5.984 0 01-1.757 4.243 1 1 0 01-1.415-1.415A3.984 3.984 0 0013 10a3.983 3.983 0 00-1.172-2.828 1 1 0 010-1.415z" clip-rule="evenodd" />
                    </svg>
                  </span>
                <% else %>
                  <span class="flex relative w-6 -translate-x-1">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clip-rule="evenodd" />
                    </svg>
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
