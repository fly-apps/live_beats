defmodule LiveBeatsWeb.SongLive.SongEntryComponent do
  use LiveBeatsWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="sm:grid sm:grid-cols-2 sm:gap-2 sm:items-start sm:border-t sm:border-gray-200 sm:pt-2">
      <div class="border border-gray-300 rounded-md px-3 py-2 mt-2 shadow-sm focus-within:ring-1 focus-within:ring-indigo-600 focus-within:border-indigo-600">
        <label for="name" class="block text-xs font-medium text-gray-900">Title</label>
        <input type="text" name={"songs[#{@ref}][title]"} value={@title}
          class="block w-full border-0 p-0 text-gray-900 placeholder-gray-500 focus:ring-0 sm:text-sm"/>
        <%= error_tag(@errors, :title, "songs[#{@ref}][title]") %>
      </div>
      <div class="border border-gray-300 rounded-md px-3 py-2 mt-2 shadow-sm focus-within:ring-1 focus-within:ring-indigo-600 focus-within:border-indigo-600">
        <label for="name" class="block text-xs font-medium text-gray-900">Artist</label>
        <input type="text" name={"songs[#{@ref}][artist]"} value={@artist}
          class="block w-full border-0 p-0 text-gray-900 placeholder-gray-500 focus:ring-0 sm:text-sm"/>
        <%= error_tag(@errors, :artist, "songs[#{@ref}][artist]") %>
      </div>
      <div style={"width: #{@progress}%;"} class="col-span-full bg-purple-500 dark:bg-purple-400 h-1.5 w-0 p-0">
      </div>
    </div>
    """
  end

  def update(%{progress: progress}, socket) do
    {:ok, assign(socket, progress: progress)}
  end

  def update(%{changeset: changeset, id: id}, socket) do
    {:ok,
     socket
     |> assign(ref: id)
     |> assign(:errors, changeset.errors)
     |> assign(title: Ecto.Changeset.get_field(changeset, :title))
     |> assign(artist: Ecto.Changeset.get_field(changeset, :artist))
     |> assign_new(:progress, fn -> 0 end)}
  end
end
