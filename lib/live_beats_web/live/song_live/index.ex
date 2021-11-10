defmodule LiveBeatsWeb.SongLive.Index do
  use LiveBeatsWeb, :live_view

  alias LiveBeats.{MediaLibrary, MP3Stat}
  alias LiveBeatsWeb.LayoutComponent
  alias LiveBeatsWeb.SongLive.{SongRowComponent, UploadFormComponent}

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
      module={SongRowComponent}
      rows={@songs}
      row_id={fn song -> "song-#{song.id}" end}
    >
      <:col let={%{song: song}} label="Title"><%= song.title %></:col>
      <:col let={%{song: song}} label="Artist"><%= song.artist %></:col>
      <:col let={%{song: song}} label="Attribution" class="max-w-5xl break-words text-gray-600 font-light"><%= song.attribution %></:col>
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
    %{current_user: current_user} = socket.assigns

    if connected?(socket) do
      MediaLibrary.subscribe(current_user)
    end

    active_id =
      if song = MediaLibrary.get_current_active_song(current_user.id) do
        SongRowComponent.send_status(song.id, song.status)
        song.id
      end

    {:ok, assign(socket, songs: list_songs(), active_id: active_id), temporary_assigns: [songs: []]}
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params) |> maybe_show_modal()}
  end

  def handle_event("play_or_pause", %{"id" => id}, socket) do
    song = MediaLibrary.get_song!(id)
    if socket.assigns.active_id == id and MediaLibrary.playing?(song) do
      MediaLibrary.pause_song(song)
    else
      MediaLibrary.play_song(id)
    end

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    song = MediaLibrary.get_song!(id)
    {:ok, _} = MediaLibrary.delete_song(song)
    {:noreply, socket}
  end

  def handle_info({:play, %MediaLibrary.Song{} = song, _meta}, socket) do
    {:noreply, play_song(socket, song)}
  end

  def handle_info({:pause, %MediaLibrary.Song{} = song}, socket) do
    {:noreply, pause_song(socket, song.id)}
  end

  defp stop_song(socket, song_id) do
    SongRowComponent.send_status(song_id, :stopped)

    if socket.assigns.active_id == song_id do
      assign(socket, :active_id, nil)
    else
      socket
    end
  end

  defp pause_song(socket, song_id) do
    SongRowComponent.send_status(song_id, :paused)
    socket
  end

  defp play_song(socket, %MediaLibrary.Song{} = song) do
    %{active_id: active_id} = socket.assigns

    cond do
      active_id == song.id ->
        SongRowComponent.send_status(song.id, :playing)
        socket

      active_id ->
        SongRowComponent.send_status(song.id, :playing)

        socket
        |> stop_song(active_id)
        |> assign(active_id: song.id)

      true ->
        SongRowComponent.send_status(song.id, :playing)
        assign(socket, active_id: song.id)
    end
  end

  defp maybe_show_modal(socket) do
    if socket.assigns.live_action in [:new] do
      LayoutComponent.show_modal(UploadFormComponent, %{
        id: :new,
        confirm: {"Save", type: "submit", form: "song-form"},
        patch_to: home_path(socket),
        song: socket.assigns.song,
        title: socket.assigns.page_title,
        current_user: socket.assigns.current_user
      })
    else
      LayoutComponent.hide_modal()
    end

    socket
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add Songs")
    |> assign(:song, %MediaLibrary.Song{})
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
