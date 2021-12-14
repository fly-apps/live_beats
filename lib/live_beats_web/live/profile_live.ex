defmodule LiveBeatsWeb.ProfileLive do
  use LiveBeatsWeb, :live_view

  alias LiveBeats.{Accounts, MediaLibrary, MP3Stat}
  alias LiveBeatsWeb.{LayoutComponent, Presence}
  alias LiveBeatsWeb.ProfileLive.{SongRowComponent, UploadFormComponent}

  def render(assigns) do
    ~H"""
    <.title_bar>
      <div>
        <div class="block">
          <%= @profile.tagline %> <%= if @owns_profile? do %>(you)<% end %>
        </div>
        <.link href={@profile.external_homepage_url} _target="blank" class="block text-sm text-gray-600">
          <.icon name={:code}/> <span class=""><%= url_text(@profile.external_homepage_url) %></span>
        </.link>
      </div>

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
          <.button primary patch={profile_path(@current_user, :new)}>
            <.icon name={:upload}/><span class="ml-2">Upload Songs</span>
          </.button>
        <% end %>
      </:actions>
    </.title_bar>

    <Presence.listening_now presences={@presences}>
      <:title let={user}><%= user.username %></:title>
    </Presence.listening_now>

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
      owns_profile?={@owns_profile?}
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
      |> assign_presences()

    {:ok, socket, temporary_assigns: [songs: []]}
  end

  def handle_params(params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
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

  def handle_info({Accounts, %Accounts.Events.ActiveProfileChanged{} = event}, socket) do
    {:noreply, assign(socket, active_profile_id: event.new_profile_user_id)}
  end

  def handle_info({MediaLibrary, %MediaLibrary.Events.PublicProfileUpdated{} = update}, socket) do
    {:noreply,
     socket
     |> assign(profile: update.profile)
     |> push_patch(to: profile_path(update.profile))}
  end

  def handle_info({MediaLibrary, %MediaLibrary.Events.Play{song: song}}, socket) do
    {:noreply, play_song(socket, song)}
  end

  def handle_info({MediaLibrary, %MediaLibrary.Events.Pause{song: song}}, socket) do
    {:noreply, pause_song(socket, song.id)}
  end

  def handle_info({MediaLibrary, _}, socket), do: {:noreply, socket}

  def handle_info({Accounts, _}, socket), do: {:noreply, socket}

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

  defp apply_action(socket, :new, _params) do
    if socket.assigns.owns_profile? do
      socket
      |> assign(:page_title, "Add Songs")
      |> assign(:song, %MediaLibrary.Song{})
      |> show_upload_modal()
    else
      socket
      |> put_flash(:error, "You can't do that")
      |> redirect(to: profile_path(socket.assigns.current_user))
    end
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "Listing Songs")
    |> assign(:song, nil)
  end

  defp show_upload_modal(socket) do
    LayoutComponent.show_modal(UploadFormComponent, %{
      id: :new,
      confirm: {"Save", type: "submit", form: "song-form"},
      patch: profile_path(socket.assigns.current_user),
      song: socket.assigns.song,
      title: socket.assigns.page_title,
      current_user: socket.assigns.current_user
    })

    socket
  end

  defp list_songs(socket) do
    assign(socket, songs: MediaLibrary.list_profile_songs(socket.assigns.profile, 50))
  end

  defp assign_presences(socket) do
    users = Accounts.lists_users_by_active_profile(socket.assigns.profile.user_id, limit: 10)
    assign(socket, presences: users)
  end

  defp url_text(nil), do: ""

  defp url_text(url_str) do
    uri = URI.parse(url_str)
    uri.host <> uri.path
  end
end
