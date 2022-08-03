defmodule LiveBeatsWeb.ProfileLive.SongEntryComponent do
  use LiveBeatsWeb, :live_component

  alias LiveBeats.MP3Stat

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
              (calculating duration
              <.spinner class="inline-block animate-spin h-2.5 w-2.5 text-gray-400" />)
            </span>
          <% end %>
        </label>
        <input
          type="text"
          name={"songs[#{@ref}][title]"}
          value={@title}
          class="block w-full border-0 p-0 text-gray-900 placeholder-gray-500 focus:ring-0 sm:text-sm"
          {%{autofocus: @index == 0}}
        />
      </div>
      <div class="border border-gray-300 rounded-md px-3 py-2 mt-2 shadow-sm focus-within:ring-1 focus-within:ring-indigo-600 focus-within:border-indigo-600">
        <label for="name" class="block text-xs font-medium text-gray-900">Artist</label>
        <input
          type="text"
          name={"songs[#{@ref}][artist]"}
          value={@artist}
          class="block w-full border-0 p-0 text-gray-900 placeholder-gray-500 focus:ring-0 sm:text-sm"
        />
      </div>
      <div class="col-span-full sm:grid sm:grid-cols-2 sm:gap-2 sm:items-start">
        <.error input_name={"songs[#{@ref}][title]"} field={:title} errors={@errors} class="-mt-1" />
        <.error input_name={"songs[#{@ref}][artist]"} field={:artist} errors={@errors} class="-mt-1" />
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
        <.error
          input_name={"songs[#{@ref}][attribution]"}
          field={:attribution}
          errors={@errors}
          class="-mt-1"
        />
      </div>
      <div
        role="progressbar"
        aria-valuemin="0"
        aria-valuemax="100"
        aria-valuenow={@progress}
        style={"transition: width 0.5s ease-in-out; width: #{@progress}%; min-width: 1px;"}
        class="col-span-full bg-purple-500 dark:bg-purple-400 h-1.5 w-0 p-0"
      >
      </div>
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
     |> assign(:errors, changeset.errors)
     |> assign(title: Ecto.Changeset.get_field(changeset, :title))
     |> assign(artist: Ecto.Changeset.get_field(changeset, :artist))
     |> assign(duration: Ecto.Changeset.get_field(changeset, :duration))
     |> assign(attribution: Ecto.Changeset.get_field(changeset, :attribution))
     |> assign_new(:progress, fn -> 0 end)}
  end
end
