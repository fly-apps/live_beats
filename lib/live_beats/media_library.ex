defmodule LiveBeats.MediaLibrary do
  @moduledoc """
  The MediaLibrary context.
  """

  import Ecto.Query, warn: false
  alias LiveBeats.Repo

  alias LiveBeats.MediaLibrary.{Song, Genre}

  def store_mp3(%Song{} = song, tmp_path) do
    File.mkdir_p!("priv/static/uploads/songs")
    File.cp!(tmp_path, song.mp3_path)
  end

  def import_songs(changesets, consome_file)
      when is_map(changesets) and is_function(consome_file, 2) do
    changesets
    |> Enum.reduce(Ecto.Multi.new(), fn {ref, chset}, acc ->
      chset =
        chset
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
           consome_file.(ref, fn tmp_path -> store_mp3(song, tmp_path) end)
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

  def list_songs do
    Repo.all(Song)
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
end
