defmodule LiveBeatsWeb.AutocompleteInput do
  use LiveBeatsWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <label for="combobox" class="block text-sm font-medium text-gray-700">Genre</label>
      <div class="relative mt-1">
      <input type="hidden" name={@name} value={@value}/>
        <%= if @selected_option do %>
          <span class="inline-flex items-center px-3 py-0.5 rounded-full text-md font-medium bg-indigo-100 text-indigo-800">
            <svg class="-ml-1 mr-1.5 h-2 w-2 text-indigo-400" fill="currentColor" viewBox="0 0 8 8">
              <circle cx="4" cy="4" r="3" />
            </svg>
            <%= @title_func.(@selected_option) %>
          </span>
          <.link phx-click="change" phx-target={@myself} class="text-indigo-500 text-sm ml-2">change</.link>
        <% else %>
          <input
            id={"#{@id}-combobox"}
            name="ac_value"
            phx-change="suggest"
            phx-target={@myself}
            type="text"
            class="w-full rounded-md border border-gray-300 bg-white py-2 pl-3 pr-12 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500 sm:text-sm"
            role="combobox"
            aria-controls="options"
            aria-expanded="false"
          >
          <button type="button" class="absolute inset-y-0 right-0 flex items-center rounded-r-md px-2 focus:outline-none">
            <.icon name={:selector}/>
          </button>

          <ul id={"#{@id}-options"}
            class={"#{if @options == [], do: "hidden"} absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm"}
            role="listbox"
          >
            <%= for option <- @options do %>
              <li
                phx-click={JS.push("select", value: %{id: option.id}, target: @myself)}
                class="group relative cursor-default select-none py-2 pl-3 pr-9 text-gray-900 hover:text-white hover:bg-indigo-600"
                role="option"
                tabindex="-1"
              >
                <%= if @selected_option && @selected_option.id == option.id do %>
                  <span class="block truncate font-semibold"><%= @title_func.(option) %></span>
                  <span class="absolute inset-y-0 right-0 flex items-center pr-4 text-indigo-600 group-hover:text-white">
                    <.icon name={:check}/>
                  </span>
                <% else %>
                  <span class="block truncate"><%= @title_func.(option) %></span>
                <% end %>
              </li>
            <% end %>
          </ul>
        <% end %>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    %{id: id, suggest: suggest, get: get, title: title_func, name: name, value: value_func} =
      assigns

    {:ok,
     socket
     |> assign(id: "ac-#{id}", name: name, value: nil)
     |> assign(title_func: title_func)
     |> assign(value_func: value_func)
     |> assign(suggest_func: suggest)
     |> assign(get_func: get)
     |> assign_new(:selected_option, fn -> nil end)
     |> assign_new(:options, fn -> [] end)}
  end

  def handle_event("select", %{"id" => id}, socket) do
    selected = socket.assigns.get_func.(id)
    value = socket.assigns.value_func.(selected)
    {:noreply, assign(socket, selected_option: selected, value: value)}
  end

  def handle_event("change", _, socket) do
    {:noreply, assign(socket, selected_option: nil, value: nil)}
  end

  def handle_event("suggest", %{"ac_value" => str}, socket) do
    {:noreply, assign(socket, :options, socket.assigns.suggest_func.(str))}
  end
end

defmodule LiveBeatsWeb.ProfileLive.SongEntryComponent do
  use LiveBeatsWeb, :live_component

  alias LiveBeats.{MediaLibrary, MP3Stat}
  alias LiveBeatsWeb.AutocompleteInput

  def send_progress(%Phoenix.LiveView.UploadEntry{} = entry) do
    send_update(__MODULE__, id: entry.ref, progress: entry.progress)
  end

  def render(assigns) do
    ~H"""
    <div class="sm:grid sm:grid-cols-2 sm:gap-2 sm:items-start sm:border-t sm:border-gray-200 sm:pt-2">
      <div class="border border-gray-300 rounded-md px-3 py-2 mt-2 shadow-sm focus-within:ring-1 focus-within:ring-indigo-600 focus-within:border-indigo-600">
        <label for="name" class="block text-xs font-medium text-gray-900">
          <%= if @duration do %>
            Title <span class="text-gray-400">(<%= MP3Stat.to_mmss(@duration) %>)</span>
          <% else %>
            Title
            <span class="text-gray-400">
              (calculating duration <.spinner class="inline-block animate-spin h-2.5 w-2.5 text-gray-400"/>)
            </span>
          <% end %>
        </label>
        <input type="text" name={"songs[#{@ref}][title]"} value={@title}
          class="block w-full border-0 p-0 text-gray-900 placeholder-gray-500 focus:ring-0 sm:text-sm" {%{autofocus: @index == 0}}/>
      </div>
      <div class="border border-gray-300 rounded-md px-3 py-2 mt-2 shadow-sm focus-within:ring-1 focus-within:ring-indigo-600 focus-within:border-indigo-600">
        <label for="name" class="block text-xs font-medium text-gray-900">Artist</label>
        <input type="text" name={"songs[#{@ref}][artist]"} value={@artist}
          class="block w-full border-0 p-0 text-gray-900 placeholder-gray-500 focus:ring-0 sm:text-sm"/>
      </div>
      <div class="col-span-full sm:grid sm:grid-cols-2 sm:gap-2 sm:items-start">
        <.error input_name={"songs[#{@ref}][title]"} field={:title} errors={@errors} class="-mt-1"/>
        <.error input_name={"songs[#{@ref}][artist]"} field={:artist} errors={@errors} class="-mt-1"/>
      </div>
      <div class="border col-span-full border-gray-300 rounded-md px-3 py-2 mt-2 shadow-sm focus-within:ring-1 focus-within:ring-indigo-600 focus-within:border-indigo-600">
        <label for="name" class="block text-xs font-medium text-gray-900">
          License Attribution <span class="text-gray-400">(as required by artist)</span>
        </label>
        <textarea
          name={"songs[#{@ref}][attribution]"}
          class="block w-full border-0 p-0 text-gray-900 placeholder-gray-500 focus:ring-0 sm:text-xs"
        ><%= @attribution %></textarea>
      </div>
      <div class="col-span-full sm:grid sm:grid-cols-2 sm:gap-2 sm:items-start">
        <.error input_name={"songs[#{@ref}][attribution]"} field={:attribution} errors={@errors} class="-mt-1"/>
      </div>

      <.live_component
        module={AutocompleteInput}
        id={@ref}
        title={fn genre -> genre.title end}
        get={&MediaLibrary.get_genre!/1}
        suggest={&MediaLibrary.suggest_genres/1}
        name={"songs[#{@ref}][genre_id]"}
        value={fn genre -> genre.id end}
      />

      <div
        role="progressbar"
        aria-valuemin="0"
        aria-valuemax="100"
        aria-valuenow={@progress}
        style={"transition: width 0.5s ease-in-out; width: #{@progress}%; min-width: 1px;"}
        class="col-span-full bg-purple-500 dark:bg-purple-400 h-1.5 w-0 p-0"
      ></div>
    </div>
    """
  end

  def update(%{progress: progress}, socket) do
    {:ok, assign(socket, progress: progress)}
  end

  def update(%{changeset: changeset, id: id, index: index}, socket) do
    {:ok,
     socket
     |> assign(ref: id)
     |> assign(index: index)
     |> assign(options: [])
     |> assign(:errors, changeset.errors)
     |> assign(title: Ecto.Changeset.get_field(changeset, :title))
     |> assign(artist: Ecto.Changeset.get_field(changeset, :artist))
     |> assign(duration: Ecto.Changeset.get_field(changeset, :duration))
     |> assign(attribution: Ecto.Changeset.get_field(changeset, :attribution))
     |> assign_new(:progress, fn -> 0 end)
     |> assign_new(:selected_option, fn -> nil end)}
  end

  def handle_event(
        "artist_changed",
        %{"_target" => ["songs", idx, "artist"], "songs" => song_params},
        socket
      ) do
    IO.inspect(Map.fetch!(song_params, idx))
    {:noreply, socket}
  end
end
