defmodule LiveBeats.MediaLibrary do
  @moduledoc """
  The MediaLibrary context.
  """

  import Ecto.Query, warn: false
  alias LiveBeats.{Repo, MP3Stat, Accounts}
  alias LiveBeats.MediaLibrary.{Song, Genre}

  @pubsub LiveBeats.PubSub

  def subscribe(%Accounts.User{} = user) do
    Phoenix.PubSub.subscribe(@pubsub, topic(user.id))
  end

  def play_song(%Song{id: id}), do: play_song(id)

  def play_song(id) do
    song = get_song!(id)
    Phoenix.PubSub.broadcast!(@pubsub, topic(song.user_id), {:play, song, %{began_at: now_ms()}})
  end

  def pause_song(%Song{} = song) do
    Phoenix.PubSub.broadcast!(@pubsub, topic(song.user_id), {:pause, song})
  end

  defp topic(user_id), do: "room:#{user_id}"

  def store_mp3(%Song{} = song, tmp_path) do
    dir = "priv/static/uploads/songs"
    File.mkdir_p!(dir)
    File.cp!(tmp_path, Path.join(dir, song.mp3_filename))
  end

  def put_stats(%Ecto.Changeset{} = changeset, %MP3Stat{} = stat) do
    Ecto.Changeset.put_change(changeset, :duration, stat.duration)
  end

  def import_songs(%Accounts.User{} = user, changesets, consume_file)
      when is_map(changesets) and is_function(consume_file, 2) do
    changesets
    |> Enum.reduce(Ecto.Multi.new(), fn {ref, chset}, acc ->
      chset =
        chset
        |> Song.put_user(user)
        |> Song.put_mp3_path()
        |> Map.put(:action, nil)

      Ecto.Multi.insert(acc, {:song, ref}, chset)
    end)
    |> LiveBeats.Repo.transaction()
    |> case do
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

  def list_songs(limit \\ 100) do
    Repo.all(from s in Song, limit: ^limit, order_by: [asc: s.inserted_at])
  end

  def get_song!(id), do: Repo.get!(Song, id)

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
    Repo.delete(song)
  end

  def change_song(%Song{} = song, attrs \\ %{}) do
    Song.changeset(song, attrs)
  end

  defp now_ms, do: System.system_time() |> System.convert_time_unit(:native, :millisecond)
end
