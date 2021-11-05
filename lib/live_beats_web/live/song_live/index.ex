defmodule LiveBeatsWeb.SongLive.Index do
  use LiveBeatsWeb, :live_view

  alias LiveBeats.{MediaLibrary, MP3Stat}
  alias LiveBeats.MediaLibrary.Song
  alias LiveBeatsWeb.LayoutComponent

  def render(assigns) do
    ~H"""
    <.title_bar>
      Listing Songs

      <:actions>
        <.button primary patch_to={Routes.song_index_path(@socket, :new)}>Upload Songs</.button>
      </:actions>
    </.title_bar>

    <%= for song <- @songs, id = "delete-modal-#{song.id}" do %>
      <.modal
        id={id}
        on_confirm={JS.push("delete", value: %{id: song.id}) |> hide_modal(id) |> hide("#song-#{song.id}")}
      >
        Are you sure you want to delete "<%= song.title %>"?
        <:cancel>Cancel</:cancel>
        <:confirm>Delete</:confirm>
      </.modal>
    <% end %>

    <.live_table
      module={LiveBeatsWeb.SongLive.SongRow}
      rows={@songs}
      row_id={fn song -> "song-#{song.id}" end}
    >
      <:col let={%{song: song}} label="Title"><%= song.title %></:col>
      <:col let={%{song: song}} label="Artist"><%= song.artist %></:col>
      <:col let={%{song: song}} label="Duration"><%= MP3Stat.to_mmss(song.duration) %></:col>
      <:col let={%{song: song}} label="">
        <.link phx-click={show_modal("delete-modal-#{song.id}")} class="inline-flex items-center px-3 py-2 text-sm leading-4 font-medium">
          <.icon name={:trash} class="-ml-0.5 mr-2 h-4 w-4"/>
          Delete
        </.link>
      </:col>
    </.live_table>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      MediaLibrary.subscribe(socket.assigns.current_user)
    end

    {:ok, assign(socket, songs: list_songs(), active_id: nil), temporary_assigns: [songs: []]}
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params) |> maybe_show_modal()}
  end

  def handle_event("play-song", %{"id" => id}, socket) do
    MediaLibrary.play_song(id)
    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    song = MediaLibrary.get_song!(id)
    {:ok, _} = MediaLibrary.delete_song(song)
    {:noreply, socket}
  end

  def handle_info({:play, %Song{} = song, _meta}, socket) do
    {:noreply, play_song(socket, song)}
  end

  def handle_info({:pause, %Song{} = song}, socket) do
    {:noreply, pause_song(socket, song.id)}
  end

  defp pause_song(socket, song_id) do
    send_update(LiveBeatsWeb.SongLive.SongRow, id: "song-#{song_id}", action: :deactivate)
    socket
  end

  defp play_song(socket, %Song{} = song) do
    send_update(LiveBeatsWeb.SongLive.SongRow, id: "song-#{song.id}", action: :activate)

    if socket.assigns.active_id do
      socket
      |> pause_song(socket.assigns.active_id)
      |> assign(active_id: song.id)
    else
      assign(socket, active_id: song.id)
    end
  end

  defp maybe_show_modal(socket) do
    if socket.assigns.live_action in [:new, :edit] do
      LayoutComponent.show_modal(LiveBeatsWeb.SongLive.UploadFormComponent, %{
        confirm: {"Save", type: "submit", form: "song-form"},
        patch_to: Routes.song_index_path(socket, :index),
        id: socket.assigns.song.id || :new,
        title: socket.assigns.page_title,
        action: socket.assigns.live_action,
        song: socket.assigns.song,
        current_user: socket.assigns.current_user,
        genres: socket.assigns.genres
      })
    else
      LayoutComponent.hide_modal()
    end

    socket
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add Songs")
    |> assign(:song, %Song{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Songs")
    |> assign(:song, nil)
  end

  defp list_songs do
    MediaLibrary.list_songs(50)
  end
end
