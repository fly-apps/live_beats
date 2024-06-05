defmodule LiveBeatsWeb.ProfileLive do
  use LiveBeatsWeb, :live_view

  alias LiveBeats.{Accounts, MediaLibrary, MP3Stat}
  alias LiveBeatsWeb.Presence
  alias LiveBeatsWeb.ProfileLive.{UploadFormComponent}

  @max_presences 20

  def render(assigns) do
    ~H"""
    <.modal
      id="upload"
      patch={profile_path(@current_user)}
      on_cancel={JS.push("cancel", target: "#song-form")}
      phx-mounted={@live_action == :new && show_modal("upload")}
    >
      <:title>Add Music</:title>
      <.live_component
        id="upload-form"
        module={UploadFormComponent}
        current_user={@current_user}
        on_complete={hide_modal("upload")}
      />
      <:confirm type="submit" form="song-form">Save</:confirm>
      <:cancel>Cancel</:cancel>
    </.modal>
    <.title_bar>
      <div>
        <div class="block">
          <%= @profile.tagline %>
          <%= if @owns_profile? do %>
            (you)
          <% end %>
          <span>
            – <%= ngettext("%{count} song", "%{count} songs", @songs_count) %>
          </span>
        </div>
        <.link href={@profile.external_homepage_url} target="_blank" class="text-sm text-gray-600">
          <.icon name={:code} /> <span class=""><%= url_text(@profile.external_homepage_url) %></span>
        </.link>
      </div>
      <:actions>
        <%= if @active_profile_id == @profile.user_id do %>
          <.button
            :if={@songs_count > 0}
            primary
            phx-click={
              JS.push("switch_profile", value: %{user_id: nil}, target: "#player", loading: "#player")
            }
          >
            <.icon name={:stop} /><span class="ml-2">Stop Listening</span>
          </.button>
        <% else %>
          <.button
            :if={@songs_count > 0}
            primary
            phx-click={
              JS.push("switch_profile",
                value: %{user_id: to_string(@profile.user_id)},
                target: "#player",
                loading: "#player"
              )
            }
          >
            <.icon name={:play} /><span class="ml-2">Listen</span>
          </.button>
        <% end %>
        <.button
          :if={@owns_profile?}
          id="upload-btn"
          primary
          phx-click={show_modal("upload") |> JS.patch(profile_upload_path(@current_user))}
        >
          <.icon name={:upload} /><span class="ml-2">Upload Songs</span>
        </.button>
      </:actions>
    </.title_bar>

    <Presence.listening_now
      presences={@presences}
      presence_ids={@presence_ids}
      total_count={@presences_count}
    />

    <div id={"trascript-#{@active_song_id}"} phx-update="stream" class="mt-10 px-6">
      <div :for={{id, segment} <- @streams.transcript_segments} id={id}>
        <span class="text-gray-400">[<%= LiveBeats.MP3Stat.to_mmss(segment.ss) %>]</span>
        <%= segment.text %>
      </div>
    </div>

    <div :if={@owns_profile?} id="dialogs" phx-update="stream">
      <.modal
        :for={{_id, song} <- @streams.songs}
        :if={song.id}
        id={"delete-modal-#{song.id}"}
        on_confirm={
          JS.push("delete", value: %{id: to_string(song.id)})
          |> hide_modal("delete-modal-#{song.id}")
          |> focus_closest("#song-#{song.id}")
          |> hide("#songs-#{song.id}")
        }
        on_cancel={focus("#delete-modal-#{song.id}", "#delete-song-#{song.id}")}
      >
        Are you sure you want to delete "<%= song.title %>"?
        <:cancel>Cancel</:cancel>
        <:confirm>Delete</:confirm>
      </.modal>
    </div>

    <div :if={@songs_count == 0} class="my-2 text-center">
      <.icon name={:music_note} class="mx-auto h-12 w-12 text-gray-400" />
      <h3 class="mt-2 text-sm font-semibold text-gray-900">No music</h3>
      <p class="mt-1 text-sm text-gray-500">Get started by uploading a new playlist</p>
      <div class="mt-6">
        <.button
          primary
          phx-click={show_modal("upload") |> JS.patch(profile_upload_path(@current_user))}
        >
          <.icon name={:upload} />
          <span class="ml-2">Upload songs</span>
        </.button>
      </div>
    </div>
    <div :if={@songs_count > 0}>
      <.table
        id="songs"
        rows={@streams.songs}
        row_id={fn {id, _song} -> id end}
        row_click={
          @owns_profile? &&
            fn {id, song} ->
              JS.push("play_or_pause",
                loading: "#songs tbody, ##{id}",
                value: %{id: to_string(song.id)}
              )
            end
        }
        streamable
        sortable_drop={@owns_profile? && "row_dropped"}
      >
        <:col
          :let={{_id, song}}
          label="Title"
          class!={[
            "px-6 py-3 text-sm font-medium text-gray-900 min-w-[200px] md:min-w-[20rem]",
            @owns_profile? && "cursor-pointer"
          ]}
        >
          <span :if={song.status == :playing} class="flex pt-1 relative mr-2 w-4">
            <span class="w-3 h-3 animate-ping bg-purple-400 rounded-full absolute"></span>
            <.icon name={:volume_up} class="h-5 w-5 -mt-1 -ml-1" aria-label="Playing" role="button" />
          </span>
          <span :if={song.status == :paused} class="flex pt-1 relative mr-2 w-4">
            <.icon
              name={:volume_up}
              class="h-5 w-5 -mt-1 -ml-1 text-gray-400"
              aria-label="Paused"
              role="button"
            />
          </span>
          <span :if={song.status == :stopped} class="flex relative w-6 -translate-x-1">
            <.icon
              :if={@owns_profile?}
              name={:play}
              class="h-5 w-5 text-gray-400"
              aria-label="Play"
              role="button"
            />
          </span>
          <%= song.title %>
        </:col>
        <:col :let={{_id, song}} label="Artist"><%= song.artist %></:col>
        <:col
          :let={{_id, song}}
          label="Attribution"
          class="max-w-5xl break-words text-gray-600 font-light"
        >
          <%= song.attribution %>
        </:col>
        <:col :let={{_id, song}} label="Duration">
          <%= MP3Stat.to_mmss(song.duration) %>
        </:col>
        <:col :let={{_id, song}} :if={@owns_profile?} label="">
          <.link
            id={"delete-song-#{song.id}"}
            phx-click={show_modal("delete-modal-#{song.id}")}
            class="inline-flex items-center px-3 py-2 text-sm leading-4 font-medium"
          >
            <.icon name={:trash} class="-ml-0.5 mr-2 h-4 w-4" /> Delete
          </.link>
        </:col>
      </.table>
    </div>
    """
  end

  def mount(%{"profile_username" => profile_username}, _session, socket) do
    %{current_user: current_user} = socket.assigns

    profile_user =
      if current_user.username == profile_username do
        current_user
      else
        Accounts.get_user_by!(username: profile_username)
      end

    profile = MediaLibrary.get_profile!(profile_user)

    if connected?(socket) do
      MediaLibrary.subscribe_to_profile(profile)
      Accounts.subscribe(current_user.id)
      Presence.subscribe(profile)
    end

    socket =
      socket
      |> assign(
        active_song_id: nil,
        active_profile_id: current_user.active_profile_user_id,
        profile: profile,
        owns_profile?: MediaLibrary.owns_profile?(current_user, profile)
      )
      |> stream_configure(:transcript_segments, dom_id: &"ss-#{&1.ss}")
      |> stream(:transcript_segments, [])
      |> stream_songs()
      |> assign_presences()

    {:ok, socket, temporary_assigns: [presences: %{}]}
  end

  def stream_songs(socket) do
    %{profile: profile} = socket.assigns
    songs = MediaLibrary.list_profile_songs(profile, 50)
    active_song = Enum.find(songs, fn song -> song.status in [:playing, :paused] end)
    segments = if active_song, do: active_song.transcript.segments, else: []

    socket
    |> assign(
      songs: songs,
      active_song: active_song,
      active_song_id: active_song && active_song.id,
      segments: segments,
      songs_count: Enum.count(songs)
    )
    |> stream(:songs, songs, reset: true)
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  def handle_event("play_or_pause", %{"id" => id}, socket) do
    %{active_song_id: active_song_id} = socket.assigns
    song = MediaLibrary.get_song!(id)
    can_playback? = MediaLibrary.can_control_playback?(socket.assigns.current_user, song)

    cond do
      can_playback? and active_song_id == song.id and MediaLibrary.playing?(song) ->
        MediaLibrary.pause_song(song)

        receive do
          {MediaLibrary, %MediaLibrary.Events.Pause{song: song}} ->
            {:noreply, pause_song(socket, song)}
        end

      can_playback? ->
        MediaLibrary.play_song(id)

        receive do
          {MediaLibrary, %MediaLibrary.Events.Play{song: song}} ->
            {:noreply, play_song(socket, song)}
        end

      true ->
        {:noreply, socket}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    song = MediaLibrary.get_song!(id)

    if song.user_id == socket.assigns.current_user.id do
      :ok = MediaLibrary.delete_song(song)
    end

    if song.id == socket.assigns.active_song_id do
      {:noreply, assign(socket, :active_song_id, nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("row_dropped", %{"id" => dom_id, "old" => old_idx, "new" => new_idx}, socket) do
    "songs-" <> id = dom_id
    song = MediaLibrary.get_song!(id)

    if song.user_id == socket.assigns.current_user.id and song.position == old_idx do
      :ok = MediaLibrary.update_song_position(song, new_idx)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_info({LiveBeatsWeb.Presence, %{user_joined: presence}}, socket) do
    {:noreply, assign_presence(socket, presence)}
  end

  def handle_info({LiveBeatsWeb.Presence, %{user_left: presence}}, socket) do
    %{user: user} = presence

    if presence.metas == [] do
      {:noreply, remove_presence(socket, user)}
    else
      {:noreply, socket}
    end
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

  def handle_info({MediaLibrary, %MediaLibrary.Events.NewPosition{song: song}}, socket) do
    {:noreply,
     socket
     |> stream_delete(:songs, song)
     |> stream_insert(:songs, song, at: song.position)}
  end

  def handle_info({MediaLibrary, %MediaLibrary.Events.Play{song: song}}, socket) do
    {:noreply, play_song(socket, song)}
  end

  def handle_info({MediaLibrary, %MediaLibrary.Events.Pause{song: song}}, socket) do
    {:noreply, pause_song(socket, song)}
  end

  def handle_info(
        {MediaLibrary, {%MediaLibrary.Song.Transcript.Segment{} = seg, song_id}},
        socket
      ) do
    if socket.assigns.active_song_id == song_id do
      {:noreply, stream_insert(socket, :transcript_segments, seg)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({MediaLibrary, %MediaLibrary.Events.SongsImported{songs: songs}}, socket) do
    %{current_user: current_user, active_song_id: active_song_id} = socket.assigns
    first = hd(songs)

    if !active_song_id && MediaLibrary.can_control_playback?(current_user, first) do
      MediaLibrary.play_song(first)
    end

    {:noreply,
     Enum.reduce(songs, socket, fn song, acc ->
       acc
       |> update(:songs_count, &(&1 + 1))
       |> stream_insert(:songs, song)
     end)}
  end

  def handle_info({MediaLibrary, %MediaLibrary.Events.SongDeleted{song: song}}, socket) do
    {:noreply,
     socket
     |> update(:songs_count, &(&1 - 1))
     |> stream_delete(:songs, song)}
  end

  def handle_info({MediaLibrary, {:ping, ping}}, socket) do
    %{user: user, rtt: rtt, region: region} = ping

    send_update(Presence.BadgeComponent,
      id: user.id,
      action: {:ping, %{user: user, ping: rtt, region: region}}
    )

    {:noreply, socket}
  end

  def handle_info({MediaLibrary, _}, socket), do: {:noreply, socket}

  def handle_info({Accounts, _}, socket), do: {:noreply, socket}

  defp stop_song(socket, song_id) do
    song = MediaLibrary.get_song!(song_id)

    socket =
      if socket.assigns.active_song_id == song_id do
        assign(socket, :active_song_id, nil)
      else
        socket
      end

    stream_insert(socket, :songs, %MediaLibrary.Song{song | status: :stopped})
  end

  defp pause_song(socket, %MediaLibrary.Song{} = song) do
    stream_insert(socket, :songs, %MediaLibrary.Song{song | status: :paused})
  end

  defp play_song(socket, %MediaLibrary.Song{} = song) do
    %{active_song_id: active_song_id} = socket.assigns
    song = %MediaLibrary.Song{song | status: :playing}

    cond do
      active_song_id == song.id ->
        stream_insert(socket, :songs, song)

      active_song_id ->
        socket
        |> stop_song(active_song_id)
        |> stream_insert(:songs, song)
        |> assign(active_song_id: song.id)

      true ->
        socket
        |> stream_insert(:songs, song)
        |> assign(active_song_id: song.id)
    end
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "Listing Songs")
    |> assign(:song, nil)
  end

  defp apply_action(socket, :new, _params) do
    if socket.assigns.owns_profile? do
      assign(socket, :page_title, "Add Music")
    else
      socket
      |> put_flash(:error, "You can't do that")
      |> redirect(to: profile_path(socket.assigns.current_user))
    end
  end

  defp assign_presences(socket) do
    %{profile: profile} = socket.assigns
    socket = assign(socket, presences_count: 0, presences: %{}, presence_ids: %{})

    if profile do
      profile
      |> LiveBeatsWeb.Presence.list_profile_users()
      |> Enum.reduce(socket, fn {_, presence}, acc -> assign_presence(acc, presence) end)
    else
      socket
    end
  end

  defp assign_presence(socket, presence) do
    %{user: user} = presence
    %{presence_ids: presence_ids} = socket.assigns

    cond do
      Map.has_key?(presence_ids, user.id) ->
        socket

      Enum.count(presence_ids) < @max_presences ->
        socket
        |> update(:presences, &Map.put(&1, user.id, user))
        |> update(:presence_ids, &Map.put(&1, user.id, System.system_time()))
        |> update(:presences_count, &(&1 + 1))

      true ->
        update(socket, :presences_count, &(&1 + 1))
    end
  end

  defp remove_presence(socket, user) do
    socket
    |> update(:presences, &Map.delete(&1, user.id))
    |> update(:presence_ids, &Map.delete(&1, user.id))
    |> update(:presences_count, &(&1 - 1))
  end

  defp url_text(nil), do: ""

  defp url_text(url_str) do
    uri = URI.parse(url_str)
    uri.host <> uri.path
  end
end
