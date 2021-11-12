defmodule LiveBeatsWeb.SongLive.Index do
  use LiveBeatsWeb, :live_view

  alias LiveBeats.{Accounts, MediaLibrary, MP3Stat}
  alias LiveBeatsWeb.LayoutComponent
  alias LiveBeatsWeb.SongLive.{SongRowComponent, UploadFormComponent}

  def render(assigns) do
    ~H"""
    <.title_bar>
      <%= @profile.tagline %> <%= if @owns_profile? do %>(you)<% end %>

      <:actions>
        <%= if @active_profile_id == @profile.user_id do %>
          <.button primary
            phx-click={JS.push("switch_profile", value: %{user_id: nil}, target: "#player", loading: "#player")}
          >
            <.icon name={:stop}/><span class="ml-2">Stop Listening</span>
          </.button>
        <% else %>
          <.button primary
            phx-click={JS.push("switch_profile", value: %{user_id: @profile.user_id}, target: "#player", loading: "#player")}
          >
            <.icon name={:play}/><span class="ml-2">Listen</span>
          </.button>
        <% end %>
        <%= if @owns_profile? do %>
          <.button primary patch_to={Routes.song_index_path(@socket, :new)}>
            <.icon name={:upload}/><span class="ml-2">Upload Songs</span>
          </.button>
        <% end %>
      </:actions>
    </.title_bar>

    <%= for song <- if(@owns_profile?, do: @songs, else: []), id = "delete-modal-#{song.id}" do %>
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
      <:col let={%{song: song}} label="" if={@owns_profile?}>
        <.link phx-click={show_modal("delete-modal-#{song.id}")} class="inline-flex items-center px-3 py-2 text-sm leading-4 font-medium">
          <.icon name={:trash} class="-ml-0.5 mr-2 h-4 w-4"/>
          Delete
        </.link>
      </:col>
    </.live_table>
    """
  end

  def mount(%{"profile_username" => profile_username}, _session, socket) do
    %{current_user: current_user} = socket.assigns

    profile =
      Accounts.get_user_by!(username: profile_username)
      |> MediaLibrary.get_profile!()

    if connected?(socket) do
      MediaLibrary.subscribe_to_profile(profile)
      Accounts.subscribe(current_user.id)
    end

    active_song_id =
      if song = MediaLibrary.get_current_active_song(profile) do
        SongRowComponent.send_status(song.id, song.status)
        song.id
      end

    socket =
      socket
      |> assign(
        active_song_id: active_song_id,
        active_profile_id: current_user.active_profile_user_id,
        profile: profile,
        owns_profile?: MediaLibrary.owns_profile?(current_user, profile)
      )
      |> list_songs()

    {:ok, socket, temporary_assigns: [songs: []]}
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params) |> maybe_show_modal()}
  end

  def handle_event("play_or_pause", %{"id" => id}, socket) do
    song = MediaLibrary.get_song!(id)
    can_playback? = MediaLibrary.can_control_playback?(socket.assigns.current_user, song)

    cond do
      can_playback? and socket.assigns.active_song_id == id and MediaLibrary.playing?(song) ->
        MediaLibrary.pause_song(song)

      can_playback? ->
        MediaLibrary.play_song(id)

      true ->
        :noop
    end

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    song = MediaLibrary.get_song!(id)

    if song.user_id == socket.assigns.current_user.id do
      {:ok, _} = MediaLibrary.delete_song(song)
    end

    {:noreply, socket}
  end

  def handle_info(%Accounts.Events.ActiveProfileChanged{new_profile_user_id: user_id}, socket) do
    {:noreply, assign(socket, active_profile_id: user_id)}
  end

  def handle_info(%MediaLibrary.Events.Play{song: song}, socket) do
    {:noreply, play_song(socket, song)}
  end

  def handle_info(%MediaLibrary.Events.Pause{song: song}, socket) do
    {:noreply, pause_song(socket, song.id)}
  end

  defp stop_song(socket, song_id) do
    SongRowComponent.send_status(song_id, :stopped)

    if socket.assigns.active_song_id == song_id do
      assign(socket, :active_song_id, nil)
    else
      socket
    end
  end

  defp pause_song(socket, song_id) do
    SongRowComponent.send_status(song_id, :paused)
    socket
  end

  defp play_song(socket, %MediaLibrary.Song{} = song) do
    %{active_song_id: active_song_id} = socket.assigns

    cond do
      active_song_id == song.id ->
        SongRowComponent.send_status(song.id, :playing)
        socket

      active_song_id ->
        SongRowComponent.send_status(song.id, :playing)

        socket
        |> stop_song(active_song_id)
        |> assign(active_song_id: song.id)

      true ->
        SongRowComponent.send_status(song.id, :playing)
        assign(socket, active_song_id: song.id)
    end
  end

  defp maybe_show_modal(socket) do
    if socket.assigns.live_action in [:new] do
      LayoutComponent.show_modal(UploadFormComponent, %{
        id: :new,
        confirm: {"Save", type: "submit", form: "song-form"},
        patch_to: profile_path(socket.assigns.current_user),
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

  defp list_songs(socket) do
    assign(socket, songs: MediaLibrary.list_profile_songs(socket.assigns.profile, 50))
  end
end
