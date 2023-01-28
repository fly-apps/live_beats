defmodule LiveBeats.MediaLibrary do
  @moduledoc """
  The MediaLibrary context.
  """

  require Logger
  import Ecto.Query, warn: false
  alias LiveBeats.{Repo, MP3Stat, Accounts}
  alias LiveBeats.MediaLibrary.{Profile, Song, Events, Genre}
  alias Ecto.{Multi, Changeset}

  @pubsub LiveBeats.PubSub
  @auto_next_threshold_seconds 5
  @max_songs 30

  defdelegate stopped?(song), to: Song
  defdelegate playing?(song), to: Song
  defdelegate paused?(song), to: Song

  def attach do
    LiveBeats.attach(__MODULE__, to: {Accounts, Accounts.Events.PublicSettingsChanged})
  end

  def handle_execute({Accounts, %Accounts.Events.PublicSettingsChanged{user: user}}) do
    profile = get_profile!(user)
    broadcast!(user.id, %Events.PublicProfileUpdated{profile: profile})
  end

  def subscribe_to_profile(%Profile{} = profile) do
    Phoenix.PubSub.subscribe(@pubsub, topic(profile.user_id))
  end

  def broadcast_ping(%Accounts.User{} = user, rtt, region) do
    if user.active_profile_user_id do
      broadcast!(
        user.active_profile_user_id,
        {:ping, %{user: user, rtt: rtt, region: region}}
      )
    end
  end

  def unsubscribe_to_profile(%Profile{} = profile) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(profile.user_id))
  end

  def local_filepath(filename_uuid) when is_binary(filename_uuid) do
    dir = LiveBeats.config([:files, :uploads_dir])
    Path.join([dir, "songs", filename_uuid])
  end

  def can_control_playback?(%Accounts.User{} = user, %Song{} = song) do
    user.id == song.user_id
  end

  def play_song(%Song{id: id}) do
    play_song(id)
  end

  def play_song(id) do
    song = get_song!(id)

    played_at =
      cond do
        playing?(song) ->
          song.played_at

        paused?(song) ->
          elapsed = DateTime.diff(song.paused_at, song.played_at, :second)
          DateTime.add(DateTime.utc_now(), -elapsed)

        true ->
          DateTime.utc_now()
      end

    changeset =
      Changeset.change(song, %{
        played_at: DateTime.truncate(played_at, :second),
        status: :playing
      })

    stopped_query =
      from s in Song,
        where: s.user_id == ^song.user_id and s.status in [:playing, :paused],
        update: [set: [status: :stopped]]

    {:ok, %{now_playing: new_song}} =
      Multi.new()
      |> Multi.update_all(:now_stopped, fn _ -> stopped_query end, [])
      |> Multi.update(:now_playing, changeset)
      |> Repo.transaction()

    elapsed = elapsed_playback(new_song)

    broadcast!(song.user_id, %Events.Play{song: song, elapsed: elapsed})

    new_song
  end

  def pause_song(%Song{} = song) do
    now = DateTime.truncate(DateTime.utc_now(), :second)
    set = [status: :paused, paused_at: now]
    pause_query = from(s in Song, where: s.id == ^song.id, update: [set: ^set])

    stopped_query =
      from s in Song,
        where: s.user_id == ^song.user_id and s.status in [:playing, :paused],
        update: [set: [status: :stopped]]

    {:ok, _} =
      Multi.new()
      |> Multi.update_all(:now_stopped, fn _ -> stopped_query end, [])
      |> Multi.update_all(:now_paused, fn _ -> pause_query end, [])
      |> Repo.transaction()

    broadcast!(song.user_id, %Events.Pause{song: song})
  end

  def play_next_song_auto(%Profile{} = profile) do
    song = get_current_active_song(profile) || get_first_song(profile)

    if song && elapsed_playback(song) >= song.duration - @auto_next_threshold_seconds do
      song
      |> get_next_song(profile)
      |> play_song()
    end
  end

  def play_prev_song(%Profile{} = profile) do
    song = get_current_active_song(profile) || get_first_song(profile)

    if prev_song = get_prev_song(song, profile) do
      play_song(prev_song)
    end
  end

  def play_next_song(%Profile{} = profile) do
    song = get_current_active_song(profile) || get_first_song(profile)

    if next_song = get_next_song(song, profile) do
      play_song(next_song)
    end
  end

  def store_mp3(%Song{} = song, tmp_path) do
    File.mkdir_p!(Path.dirname(song.mp3_filepath))
    File.cp!(tmp_path, song.mp3_filepath)
  end

  def put_stats(%Ecto.Changeset{} = changeset, %MP3Stat{} = stat) do
    chset = Song.put_stats(changeset, stat)

    if error = chset.errors[:duration] do
      {:error, %{duration: error}}
    else
      {:ok, chset}
    end
  end

  def import_songs(%Accounts.User{} = user, changesets, consume_file)
      when is_map(changesets) and is_function(consume_file, 2) do
    # refetch user for fresh song count
    user = Accounts.get_user!(user.id)

    multi =
      Ecto.Multi.new()
      |> lock_playlist(user.id)
      |> Ecto.Multi.run(:starting_position, fn repo, _changes ->
        count = repo.one(from s in Song, where: s.user_id == ^user.id, select: count(s.id))
        {:ok, count - 1}
      end)

    multi =
      changesets
      |> Enum.with_index()
      |> Enum.reduce(multi, fn {{ref, chset}, i}, acc ->
        Ecto.Multi.insert(acc, {:song, ref}, fn %{starting_position: pos_start} ->
          chset
          |> Song.put_user(user)
          |> Song.put_mp3_path()
          |> Song.put_server_ip()
          |> Ecto.Changeset.put_change(:position, pos_start + i + 1)
        end)
      end)
      |> Ecto.Multi.run(:valid_songs_count, fn _repo, changes ->
        new_songs_count = changes |> Enum.filter(&match?({{:song, _ref}, _}, &1)) |> Enum.count()
        validate_songs_limit(user.songs_count, new_songs_count)
      end)
      |> Ecto.Multi.update_all(
        :update_songs_count,
        fn %{valid_songs_count: new_count} ->
          from(u in Accounts.User,
            where: u.id == ^user.id and u.songs_count == ^user.songs_count,
            update: [inc: [songs_count: ^new_count]]
          )
        end,
        []
      )
      |> Ecto.Multi.run(:is_songs_count_updated?, fn _repo, %{update_songs_count: result} ->
        case result do
          {1, _} -> {:ok, user}
          _ -> {:error, :invalid}
        end
      end)

    case LiveBeats.Repo.transaction(multi) do
      {:ok, results} ->
        songs =
          results
          |> Enum.filter(&match?({{:song, _ref}, _}, &1))
          |> Enum.map(fn {{:song, ref}, song} ->
            consume_file.(ref, fn tmp_path -> store_mp3(song, tmp_path) end)
            {ref, song}
          end)

        broadcast_imported(user, songs)

        {:ok, Enum.into(songs, %{})}

      {:error, failed_op, failed_val, _changes} ->
        failed_op =
          case failed_op do
            {:song, _number} -> "Invalid song (#{failed_val.changes.title})"
            :is_songs_count_updated? -> :invalid
            failed_op -> failed_op
          end

        {:error, {failed_op, failed_val}}
    end
  end

  defp broadcast_imported(%Accounts.User{} = user, songs) do
    songs = Enum.map(songs, fn {_ref, song} -> song end)
    broadcast!(user.id, %Events.SongsImported{user_id: user.id, songs: songs})
  end

  def parse_file_name(name) do
    case Regex.split(~r/[-–]/, Path.rootname(name), parts: 2) do
      [title] -> %{title: String.trim(title), artist: nil}
      [title, artist] -> %{title: String.trim(title), artist: String.trim(artist)}
    end
  end

  def create_genre(attrs \\ %{}) do
    %Genre{}
    |> Genre.changeset(attrs)
    |> Repo.insert()
  end

  def list_genres do
    Repo.replica().all(Genre, order_by: [asc: :title])
  end

  def list_profile_songs(%Profile{} = profile, limit \\ 100) do
    from(s in Song,
      where: s.user_id == ^profile.user_id,
      limit: ^limit
    )
    |> order_by_playlist(:asc)
    |> Repo.replica().all()
  end

  def list_active_profiles(opts) do
    from(s in Song,
      inner_join: u in LiveBeats.Accounts.User,
      on: s.user_id == u.id,
      where: s.status in [:playing],
      limit: ^Keyword.fetch!(opts, :limit),
      order_by: [desc: s.updated_at],
      select: struct(u, [:id, :username, :profile_tagline, :avatar_url, :external_homepage_url])
    )
    |> Repo.replica().all()
    |> Enum.map(&get_profile!/1)
  end

  def get_current_active_song(%Profile{user_id: user_id}) do
    Repo.replica().one(
      from s in Song, where: s.user_id == ^user_id and s.status in [:playing, :paused]
    )
  end

  def get_profile!(%Accounts.User{} = user) do
    %Profile{
      user_id: user.id,
      username: user.username,
      tagline: user.profile_tagline,
      avatar_url: user.avatar_url,
      external_homepage_url: user.external_homepage_url
    }
  end

  def owns_profile?(%Accounts.User{} = user, %Profile{} = profile) do
    user.id == profile.user_id
  end

  def owns_song?(%Profile{} = profile, %Song{} = song) do
    profile.user_id == song.user_id
  end

  def elapsed_playback(%Song{} = song) do
    cond do
      playing?(song) ->
        start_seconds = song.played_at |> DateTime.to_unix()
        System.os_time(:second) - start_seconds

      paused?(song) ->
        DateTime.diff(song.paused_at, song.played_at, :second)

      stopped?(song) ->
        0
    end
  end

  def get_song!(id), do: Repo.replica().get!(Song, id)

  def get_first_song(%Profile{user_id: user_id}) do
    from(s in Song,
      where: s.user_id == ^user_id,
      limit: 1
    )
    |> order_by_playlist(:asc)
    |> Repo.replica().one()
  end

  def get_last_song(%Profile{user_id: user_id}) do
    from(s in Song,
      where: s.user_id == ^user_id,
      limit: 1
    )
    |> order_by_playlist(:desc)
    |> Repo.replica().one()
  end

  def get_next_song(%Song{} = song, %Profile{} = profile) do
    next =
      from(s in Song,
        where: s.user_id == ^song.user_id and s.position > ^song.position,
        limit: 1
      )
      |> order_by_playlist(:asc)
      |> Repo.replica().one()

    next || get_first_song(profile)
  end

  def get_prev_song(%Song{} = song, %Profile{} = profile) do
    prev =
      from(s in Song,
        where: s.user_id == ^song.user_id and s.position < ^song.position,
        limit: 1
      )
      |> order_by_playlist(:desc)
      |> Repo.replica().one()

    prev || get_last_song(profile)
  end

  def update_song_position(%Song{} = song, new_index) do
    old_index = song.position

    multi =
      Ecto.Multi.new()
      |> lock_playlist(song.user_id)
      |> Ecto.Multi.run(:index, fn repo, _changes ->
        case repo.one(from s in Song, where: s.user_id == ^song.user_id, select: count(s.id)) do
          count when new_index < count -> {:ok, new_index}
          count -> {:ok, count - 1}
        end
      end)
      |> multi_update_all(:dec_positions, fn %{index: new_index} ->
        from(s in Song,
          where: s.user_id == ^song.user_id and s.id != ^song.id,
          where: s.position > ^old_index and s.position <= ^new_index,
          update: [inc: [position: -1]]
        )
      end)
      |> multi_update_all(:inc_positions, fn %{index: new_index} ->
        from(s in Song,
          where: s.user_id == ^song.user_id and s.id != ^song.id,
          where: s.position < ^old_index and s.position >= ^new_index,
          update: [inc: [position: 1]]
        )
      end)
      |> multi_update_all(:position, fn %{index: new_index} ->
        from(s in Song,
          where: s.id == ^song.id,
          update: [set: [position: ^new_index]]
        )
      end)

    case LiveBeats.Repo.transaction(multi) do
      {:ok, _} ->
        broadcast!(song.user_id, %Events.NewPosition{song: %Song{song | position: new_index}})
        :ok

      {:error, failed_op, _failed_val, _changes} ->
        {:error, failed_op}
    end
  end

  def update_song(%Song{} = song, attrs) do
    song
    |> Song.changeset(attrs)
    |> Repo.update()
  end

  def delete_song(%Song{} = song) do
    delete_song_file(song)
    old_index = song.position

    Ecto.Multi.new()
    |> lock_playlist(song.user_id)
    |> Ecto.Multi.delete(:delete, song)
    |> multi_update_all(:dec_positions, fn _ ->
      from(s in Song,
        where: s.user_id == ^song.user_id,
        where: s.position > ^old_index,
        update: [inc: [position: -1]]
      )
    end)
    |> update_user_songs_count(song.user_id, -1)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        broadcast!(song.user_id, %Events.SongDeleted{song: song})
        :ok

      other ->
        other
    end
  end

  def expire_songs_older_than(count, interval) when interval in [:month, :day, :second] do
    admin_usernames = LiveBeats.config([:files, :admin_usernames])
    server_ip = LiveBeats.config([:files, :server_ip])

    Ecto.Multi.new()
    |> Ecto.Multi.delete_all(
      :delete_expired_songs,
      from(s in Song,
        join: u in assoc(s, :user),
        where: s.inserted_at < from_now(^(-count), ^to_string(interval)),
        where: s.server_ip == ^server_ip,
        where: u.username not in ^admin_usernames,
        select: %{user_id: s.user_id, mp3_filepath: s.mp3_filepath}
      )
    )
    |> Ecto.Multi.merge(&update_users_songs_count(&1))
    |> Repo.transaction()
    |> case do
      {:ok, transaction_result} ->
        {_deleted_songs_count, deleted_songs} = transaction_result.delete_expired_songs
        Enum.each(deleted_songs, &delete_song_file/1)

      error ->
        error
    end
  end

  defp update_users_songs_count(%{delete_expired_songs: results}) do
    {_deleted_songs_count, deleted_songs} = results

    deleted_songs
    |> Enum.reduce(%{}, &acc_user_songs/2)
    |> Enum.reduce(Ecto.Multi.new(), &decrement_user_songs_count/2)
  end

  defp decrement_user_songs_count({user_id, deleted_songs_count}, multi) do
    update_user_songs_count(multi, user_id, deleted_songs_count * -1)
  end

  defp update_user_songs_count(multi, user_id, songs_count) do
    Ecto.Multi.update_all(
      multi,
      "update_songs_count_user_#{user_id}",
      fn _ ->
        from(u in Accounts.User,
          where: u.id == ^user_id,
          update: [inc: [songs_count: ^songs_count]]
        )
      end,
      []
    )
  end

  defp acc_user_songs(%{user_id: user_id} = _song, songs_acc) do
    if Map.has_key?(songs_acc, user_id) do
      Map.put(songs_acc, user_id, songs_acc[user_id] + 1)
    else
      Map.put_new(songs_acc, user_id, 1)
    end
  end

  defp delete_song_file(song) do
    case File.rm(song.mp3_filepath) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.info(
          "unable to delete song #{song.id} at #{song.mp3_filepath}, got: #{inspect(reason)}"
        )
    end
  end

  def change_song(song_or_changeset, attrs \\ %{})

  def change_song(%Song{} = song, attrs) do
    Song.changeset(song, attrs)
  end

  @keep_changes [:duration, :mp3_filesize, :mp3_filepath]
  def change_song(%Ecto.Changeset{} = prev_changeset, attrs) do
    %Song{}
    |> change_song(attrs)
    |> Ecto.Changeset.change(Map.take(prev_changeset.changes, @keep_changes))
  end

  defp order_by_playlist(%Ecto.Query{} = query, direction) when direction in [:asc, :desc] do
    from(s in query, order_by: [{^direction, s.position}])
  end

  defp broadcast!(user_id, msg) when is_integer(user_id) do
    Phoenix.PubSub.broadcast!(@pubsub, topic(user_id), {__MODULE__, msg})
  end

  defp topic(user_id) when is_integer(user_id), do: "profile:#{user_id}"

  defp validate_songs_limit(user_songs, new_songs_count) do
    if user_songs + new_songs_count <= @max_songs do
      {:ok, new_songs_count}
    else
      {:error, :songs_limit_exceeded}
    end
  end

  defp multi_update_all(multi, name, func, opts \\ []) do
    Ecto.Multi.update_all(multi, name, func, opts)
  end

  defp lock_playlist(%Ecto.Multi{} = multi, user_id) do
    Repo.multi_transaction_lock(multi, :playlist, user_id)
  end
end
