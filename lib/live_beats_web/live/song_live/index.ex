defmodule LiveBeatsWeb.SongLive.Index do
  use LiveBeatsWeb, :live_view

  alias LiveBeats.MediaLibrary
  alias LiveBeats.MediaLibrary.Song
  alias LiveBeatsWeb.SongLive.DeleteDialogComponent

  def render(assigns) do
    ~H"""
    <.title_bar>
      Listing Songs

      <:actions>
        <.button primary patch_to={Routes.song_index_path(@socket, :new)}>Upload Songs</.button>
      </:actions>
    </.title_bar>

    <%= if @live_action in [:new, :edit] do %>
      <.modal show id="add-songs" return_to={Routes.song_index_path(@socket, :index)}>
        <.live_component
          module={LiveBeatsWeb.SongLive.UploadFormComponent}
          title={@page_title}
          id={@song.id || :new}
          action={@live_action}
          return_to={Routes.song_index_path(@socket, :index)}
          song={@song}
          genres={@genres}
        />
      </.modal>
    <% end %>

    <.live_component module={DeleteDialogComponent} id="delete-modal"/>

    <.table rows={@songs} row_id={fn song -> "song-#{song.id}" end}>
      <:col let={song} label="Title"><%= song.title %></:col>
      <:col let={song} label="Artist"><%= song.artist %></:col>
      <:col let={song} label="Duration"><%= song.duration %></:col>
      <:col let={song} label="">
        <.link redirect_to={Routes.song_show_path(@socket, :show, song)}>Show</.link>
        <.link patch_to={Routes.song_index_path(@socket, :edit, song)}>Edit</.link>
        <.link phx-click={JS.push("delete", value: %{id: song.id}) |> show_modal("delete-modal")}>Delete</.link>
      </:col>
    </.table>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :songs, list_songs())}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Song")
    |> assign(:song, MediaLibrary.get_song!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Song")
    |> assign(:song, %Song{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Songs")
    |> assign(:song, nil)
  end

  def handle_event("delete", %{"id" => id}, socket) do
    DeleteDialogComponent.send_show(MediaLibrary.get_song!(id))
    {:noreply, socket}
  end

  def handle_event("confirm-delete", %{"id" => id}, socket) do
    song = MediaLibrary.get_song!(id)
    {:ok, _} = MediaLibrary.delete_song(song)
    {:noreply, assign(socket, :songs, list_songs())}
  end

  defp list_songs do
    MediaLibrary.list_songs()
  end
end
