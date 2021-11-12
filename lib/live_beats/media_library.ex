defmodule LiveBeats.MediaLibrary do
  @moduledoc """
  The MediaLibrary context.
  """

  require Logger
  import Ecto.Query, warn: false
  alias LiveBeats.{Repo, MP3Stat, Accounts}
  alias LiveBeats.MediaLibrary.{Profile, Song, Genre}
  alias Ecto.{Multi, Changeset}

  @pubsub LiveBeats.PubSub
  @auto_next_threshold_seconds 5

  defdelegate stopped?(song), to: Song
  defdelegate playing?(song), to: Song
  defdelegate paused?(song), to: Song

  def subscribe_to_profile(%Profile{} = profile, from \\ nil) do
    Phoenix.PubSub.subscribe(@pubsub, topic(profile.user_id))
  end

  def unsubscribe_to_profile(%Profile{} = profile) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(profile.user_id))
  end

  def local_filepath(filename_uuid) when is_binary(filename_uuid) do
    Path.join("priv/uploads/songs", filename_uuid)
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

    Phoenix.PubSub.broadcast!(
      @pubsub,
      topic(song.user_id),
      {__MODULE__, :play, song, %{elapsed: elapsed}}
    )

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

    Phoenix.PubSub.broadcast!(@pubsub, topic(song.user_id), {__MODULE__, :pause, song})
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

  defp topic(user_id) when is_integer(user_id), do: "profile:#{user_id}"

  def store_mp3(%Song{} = song, tmp_path) do
    File.mkdir_p!(Path.dirname(song.mp3_filepath))
    File.cp!(tmp_path, song.mp3_filepath)
  end

  def put_stats(%Ecto.Changeset{} = changeset, %MP3Stat{} = stat) do
    chset = Song.put_duration(changeset, stat.duration)

    if error = chset.errors[:duration] do
      {:error, %{duration: error}}
    else
      {:ok, chset}
    end
  end

  def import_songs(%Accounts.User{} = user, changesets, consume_file)
      when is_map(changesets) and is_function(consume_file, 2) do
    multi =
      Enum.reduce(changesets, Ecto.Multi.new(), fn {ref, chset}, acc ->
        chset =
          chset
          |> Song.put_user(user)
          |> Song.put_mp3_path()

        Ecto.Multi.insert(acc, {:song, ref}, chset)
      end)

    case LiveBeats.Repo.transaction(multi) do
      {:ok, results} ->
        {:ok,
         results
         |> Enum.filter(&match?({{:song, _ref}, _}, &1))
         |> Enum.map(fn {{:song, ref}, song} ->
           consume_file.(ref, fn tmp_path -> store_mp3(song, tmp_path) end)
           {ref, song}
         end)
         |> Enum.into(%{})}

      {:error, _failed_op, _failed_val, _changes} ->
        {:error, :invalid}
    end
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
    Repo.all(Genre, order_by: [asc: :title])
  end

  def list_profile_songs(%Profile{} = profile, limit \\ 100) do
    from(s in Song, where: s.user_id == ^profile.user_id, limit: ^limit)
    |> order_by_playlist(:asc)
    |> Repo.all()
  end

  def get_current_active_song(%Profile{user_id: user_id}) do
    Repo.one(from s in Song, where: s.user_id == ^user_id and s.status in [:playing, :paused])
  end

  def get_profile!(%Accounts.User{} = user) do
    %Profile{user_id: user.id, username: user.username, tagline: user.profile_tagline}
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

  def get_song!(id), do: Repo.get!(Song, id)

  def get_first_song(%Profile{user_id: user_id}) do
    from(s in Song,
      where: s.user_id == ^user_id,
      limit: 1
    )
    |> order_by_playlist(:asc)
    |> Repo.one()
  end

  def get_last_song(%Profile{user_id: user_id}) do
    from(s in Song,
      where: s.user_id == ^user_id,
      limit: 1
    )
    |> order_by_playlist(:desc)
    |> Repo.one()
  end

  def get_next_song(%Song{} = song, %Profile{} = profile) do
    next =
      from(s in Song,
        where: s.user_id == ^song.user_id and s.id > ^song.id,
        limit: 1
      )
      |> order_by_playlist(:asc)
      |> Repo.one()

    next || get_first_song(profile)
  end

  def get_prev_song(%Song{} = song, %Profile{} = profile) do
    prev =
      from(s in Song,
        where: s.user_id == ^song.user_id and s.id < ^song.id,
        order_by: [desc: s.inserted_at, desc: s.id],
        limit: 1
      )
      |> order_by_playlist(:desc)
      |> Repo.one()

    prev || get_last_song(profile)
  end

  def create_song(attrs \\ %{}) do
    %Song{}
    |> Song.changeset(attrs)
    |> Repo.insert()
  end

  def update_song(%Song{} = song, attrs) do
    song
    |> Song.changeset(attrs)
    |> Repo.update()
  end

  def delete_song(%Song{} = song) do
    case File.rm(song.mp3_filepath) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.info(
          "unable to delete song #{song.id} at #{song.mp3_filepath}, got: #{inspect(reason)}"
        )
    end

    Repo.delete(song)
  end

  def change_song(song_or_changeset, attrs \\ %{})

  def change_song(%Song{} = song, attrs) do
    Song.changeset(song, attrs)
  end

  def change_song(%Ecto.Changeset{} = prev_changeset, attrs) do
    %Song{}
    |> change_song(attrs)
    |> Ecto.Changeset.change(Map.take(prev_changeset.changes, [:duration]))
  end

  defp order_by_playlist(%Ecto.Query{} = query, direction) when direction in [:asc, :desc] do
    from(s in query, order_by: [{^direction, s.inserted_at}, {^direction, s.id}])
  end
end
