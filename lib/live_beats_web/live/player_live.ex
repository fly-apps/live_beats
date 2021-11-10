defmodule LiveBeatsWeb.PlayerLive do
  use LiveBeatsWeb, {:live_view, container: {:div, []}}

  alias LiveBeats.MediaLibrary
  alias LiveBeats.MediaLibrary.Song

  on_mount {LiveBeatsWeb.UserAuth, :current_user}

  def render(assigns) do
    ~H"""
    <!-- player -->
    <div id="audio-player" phx-hook="AudioPlayer" class="w-full" >
      <div phx-update="ignore">
        <audio></audio>
      </div>
      <div class="bg-white dark:bg-gray-800 p-4">
        <div class="flex items-center space-x-3.5 sm:space-x-5 lg:space-x-3.5 xl:space-x-5">
          <div class="pr-5">
            <div class="min-w-0 max-w-xs flex-col space-y-0.5">
                <h2 class="text-black dark:text-white text-sm sm:text-sm lg:text-sm xl:text-sm font-semibold truncate">
                  <%= if @song, do: @song.title, else: raw("&nbsp;") %>
                </h2>
                <p class="text-gray-500 dark:text-gray-400 text-sm sm:text-sm lg:text-sm xl:text-sm font-medium">
                  <%= if @song, do: @song.artist, else: raw("&nbsp;") %>
                </p>
            </div>
          </div>

          <.progress_bar id="player-progress" />

          <div class="text-gray-500 dark:text-gray-400 flex-row justify-between text-sm font-medium tabular-nums"
            phx-update="ignore">
            <div id="player-time"></div>
            <div id="player-duration"></div>
          </div>
        </div>
      </div>
      <div class="bg-gray-50 text-black dark:bg-gray-900 dark:text-white px-1 sm:px-3 lg:px-1 xl:px-3 grid grid-cols-5 sm:grid-cols-7 lg:grid-cols-5 xl:grid-cols-7 items-center">
        <button type="button" class="mx-auto scale-75">
          <svg width="24" height="24" fill="none">
            <path d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
          </svg>
        </button>
        <button type="button" class="hidden sm:block lg:hidden xl:block mx-auto scale-75">
          <svg width="17" height="18">
            <path d="M0 0h2v18H0V0zM4 9l13-9v18L4 9z" fill="currentColor" />
          </svg>
        </button>
        <button type="button" class="mx-auto scale-75">
          <svg width="34" height="39" fill="none">
            <path d="M12.878 26.12c1.781 0 3.09-1.066 3.085-2.515.004-1.104-.665-1.896-1.824-2.075v-.068c.912-.235 1.505-.95 1.5-1.93.005-1.283-1.048-2.379-2.727-2.379-1.602 0-2.89.968-2.932 2.387h1.274c.03-.801.784-1.287 1.64-1.287.892 0 1.475.541 1.471 1.346.004.844-.673 1.398-1.64 1.398h-.738v1.074h.737c1.21 0 1.91.614 1.91 1.491 0 .848-.738 1.424-1.765 1.424-.946 0-1.683-.486-1.734-1.262H9.797c.055 1.424 1.317 2.395 3.08 2.395zm7.734.025c2.016 0 3.196-1.645 3.196-4.504 0-2.838-1.197-4.488-3.196-4.488-2.003 0-3.196 1.645-3.2 4.488 0 2.855 1.18 4.5 3.2 4.504zm0-1.138c-1.18 0-1.892-1.185-1.892-3.366.004-2.174.716-3.371 1.892-3.371 1.172 0 1.888 1.197 1.888 3.37 0 2.182-.712 3.367-1.888 3.367z" fill="currentColor" />
            <path d="M1 22c0 8.837 7.163 16 16 16s16-7.163 16-16S25.837 6 17 6" stroke="currentColor" stroke-width="1.5" />
            <path d="M17 0L9 6l8 6V0z" fill="currentColor" />
          </svg>
        </button>
        <!-- pause -->
        <button type="button" class="mx-auto scale-75" phx-click={JS.push("play_pause") |> js_play_pause()}>
          <%= if @playing do %>
            <svg id="player-pause" width="50" height="50" fill="none">
              <circle class="text-gray-300 dark:text-gray-500" cx="25" cy="25" r="24" stroke="currentColor" stroke-width="1.5" />
              <path d="M18 16h4v18h-4V16zM28 16h4v18h-4z" fill="currentColor" />
            </svg>
          <% else %>
            <svg id="player-play" width="50" height="50" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <circle id="svg_1" stroke-width="0.8" stroke="currentColor" r="11.4" cy="12" cx="12" class="text-gray-300 dark:text-gray-500"/>
              <path stroke="null" fill="currentColor" transform="rotate(90 12.8947 12.3097)" id="svg_6" d="m9.40275,15.10014l3.49194,-5.58088l3.49197,5.58088l-6.98391,0z" stroke-width="1.5" fill="none"/>
            </svg>
          <% end %>
        </button>
        <!-- /pause -->
        <button type="button" class="mx-auto scale-75">
          <svg width="34" height="39" fill="none">
            <path d="M12.878 26.12c1.781 0 3.09-1.066 3.085-2.515.004-1.104-.665-1.896-1.824-2.075v-.068c.912-.235 1.505-.95 1.5-1.93.005-1.283-1.048-2.379-2.727-2.379-1.602 0-2.89.968-2.932 2.387h1.274c.03-.801.784-1.287 1.64-1.287.892 0 1.475.541 1.471 1.346.004.844-.673 1.398-1.64 1.398h-.738v1.074h.737c1.21 0 1.91.614 1.91 1.491 0 .848-.738 1.424-1.765 1.424-.946 0-1.683-.486-1.734-1.262H9.797c.055 1.424 1.317 2.395 3.08 2.395zm7.734.025c2.016 0 3.196-1.645 3.196-4.504 0-2.838-1.197-4.488-3.196-4.488-2.003 0-3.196 1.645-3.2 4.488 0 2.855 1.18 4.5 3.2 4.504zm0-1.138c-1.18 0-1.892-1.185-1.892-3.366.004-2.174.716-3.371 1.892-3.371 1.172 0 1.888 1.197 1.888 3.37 0 2.182-.712 3.367-1.888 3.367z" fill="currentColor" />
            <path d="M33 22c0 8.837-7.163 16-16 16S1 30.837 1 22 8.163 6 17 6" stroke="currentColor" stroke-width="1.5" />
            <path d="M17 0l8 6-8 6V0z" fill="currentColor" />
          </svg>
        </button>
        <button type="button" class="hidden sm:block lg:hidden xl:block mx-auto scale-75">
          <svg width="17" height="18" viewBox="0 0 17 18" fill="none">
            <path d="M17 0H15V18H17V0Z" fill="currentColor" />
            <path d="M13 9L0 0V18L13 9Z" fill="currentColor" />
          </svg>
        </button>
        <button type="button" class="mx-auto border border-gray-300 rounded-md text-sm font-medium py-0.5 px-2 text-gray-500 dark:border-gray-600 dark:text-gray-400">
          1.0x
        </button>
      </div>

      <.modal
        id="enable-audio"
        on_confirm={js_listen_now() |> hide_modal("enable-audio")}
        data-js-show={show_modal("enable-audio")}
      >
        <:title>Start Listening now</:title>
        Your browser needs a click event to enable playback
        <:confirm>Listen Now</:confirm>
      </.modal>
    </div>
    <!-- /player -->
    """
  end

  def mount(_parmas, _session, socket) do
    if connected?(socket) and socket.assigns.current_user do
      MediaLibrary.subscribe(socket.assigns.current_user)
      send(self(), :play_current)
    end

    socket =
      assign(socket,
        song: nil,
        playing: false,
        current_user_id: socket.assigns.current_user.id,
        # todo use actual room user id
        room_user_id: socket.assigns.current_user.id
      )

    {:ok, socket, layout: false, temporary_assigns: [current_user: nil]}
  end

  def handle_event("play_pause", _, socket) do
    %{song: song, playing: playing} = socket.assigns

    cond do
      song && playing ->
        MediaLibrary.pause_song(song)
        {:noreply, assign(socket, playing: false)}

      song ->
        MediaLibrary.play_song(song)
        {:noreply, assign(socket, playing: true)}

      true ->
        {:noreply, assign(socket, playing: false)}
    end
  end

  def handle_event("next-song-auto", _, socket) do
    if socket.assigns.song do
      MediaLibrary.play_next_song_auto(socket.assigns.song.user_id)
    end
    {:noreply, socket}
  end

  def handle_info(:play_current, socket) do
    # we raced a pubsub, noop
    if socket.assigns.song do
      {:noreply, socket}
    else
      {:noreply, play_current_song(socket)}
    end
  end

  def handle_info({:pause, _}, socket) do
    {:noreply,
     socket
     |> push_event("pause", %{})
     |> assign(playing: false)}
  end

  def handle_info({:play, %Song{} = song, %{elapsed: elapsed}}, socket) do
    {:noreply, play_song(socket, song, elapsed)}
  end

  defp play_song(socket, %Song{} = song, elapsed) do
    socket
    |> push_play(song, elapsed)
    |> assign(song: song, playing: true)
  end

  defp js_play_pause(%JS{} = js) do
    JS.dispatch(js, "js:play_pause", to: "#audio-player")
  end

  defp js_listen_now(js \\ %JS{}) do
    JS.dispatch(js, "js:listen_now", to: "#audio-player")
  end

  defp play_current_song(socket) do
    song = MediaLibrary.get_current_active_song(socket.assigns.room_user_id)

    cond do
      song && MediaLibrary.playing?(song) ->
        play_song(socket, song, MediaLibrary.elapsed_playback(song))

      song && MediaLibrary.paused?(song) ->
        assign(socket, song: song, playing: false)

      true ->
        socket
    end
  end

  defp push_play(socket, %Song{} = song, elapsed) do
    token = Phoenix.Token.sign(socket.endpoint, "file", song.mp3_filename)
    push_event(socket, "play", %{
      paused: Song.paused?(song),
      elapsed: elapsed,
      token: token,
      url: song.mp3_url
    })
  end
end
