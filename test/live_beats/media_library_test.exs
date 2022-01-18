defmodule LiveBeats.MediaLibraryTest do
  use LiveBeats.DataCase

  alias LiveBeats.MediaLibrary
  alias LiveBeats.Accounts
  alias LiveBeats.MediaLibrary.Song
  import LiveBeats.AccountsFixtures
  import LiveBeats.MediaLibraryFixtures

  describe "songs" do
    @invalid_attrs %{
      album_artist: nil,
      artist: nil,
      date_recorded: nil,
      date_released: nil,
      duration: nil,
      title: nil
    }

    test "list_profile_songs/1 returns all songs for a profile" do
      user = user_fixture()
      profile = MediaLibrary.get_profile!(user)
      song = song_fixture(%{user_id: user.id})
      assert MediaLibrary.list_profile_songs(profile) == [song]
    end

    test "get_song!/1 returns the song with given id" do
      song = song_fixture()
      assert MediaLibrary.get_song!(song.id) == song
    end

    test "update_song/2 with valid data updates the song" do
      song = song_fixture()

      update_attrs = %{
        album_artist: "some updated album_artist",
        artist: "some updated artist",
        date_recorded: ~N[2021-10-27 20:11:00],
        date_released: ~N[2021-10-27 20:11:00],
        duration: 43,
        title: "some updated title"
      }

      assert {:ok, %Song{} = song} = MediaLibrary.update_song(song, update_attrs)
      assert song.album_artist == "some updated album_artist"
      assert song.artist == "some updated artist"
      assert song.date_recorded == ~N[2021-10-27 20:11:00]
      assert song.date_released == ~N[2021-10-27 20:11:00]
      assert song.duration == 42
      assert song.title == "some updated title"
    end

    test "update_song/2 with invalid data returns error changeset" do
      song = song_fixture()
      assert {:error, %Ecto.Changeset{}} = MediaLibrary.update_song(song, @invalid_attrs)
      assert song == MediaLibrary.get_song!(song.id)
    end

    test "delete_song/1 deletes the song and decrement the user's songs_count" do
      user = user_fixture()

      user
      |> Ecto.Changeset.change(songs_count: 10)
      |> LiveBeats.Repo.update()

      song = song_fixture(%{user_id: user.id})
      assert :ok = MediaLibrary.delete_song(song)
      assert_raise Ecto.NoResultsError, fn -> MediaLibrary.get_song!(song.id) end
      assert Accounts.get_user(user.id).songs_count == 9
    end

    test "change_song/1 returns a song changeset" do
      song = song_fixture()
      assert %Ecto.Changeset{} = MediaLibrary.change_song(song)
    end
  end

  describe "expire_songs_older_than/2" do
    setup do
      today = DateTime.utc_now()

      creation_dates = Enum.map([-1, -3, -4], &add_n_months(today, &1))

      %{creation_dates: creation_dates}
    end

    test "deletes the songs expired before the required interval", %{
      creation_dates: [one_month_ago, three_months_ago, four_months_ago]
    } do
      user = user_fixture()

      expired_song_1 =
        song_fixture(user_id: user.id, title: "song1", inserted_at: four_months_ago)

      expired_song_2 =
        song_fixture(user_id: user.id, title: "song2", inserted_at: three_months_ago)

      active_song = song_fixture(user_id: user.id, title: "song3", inserted_at: one_month_ago)

      MediaLibrary.expire_songs_older_than(2, :month)

      assert_raise Ecto.NoResultsError, fn -> MediaLibrary.get_song!(expired_song_1.id) end
      assert_raise Ecto.NoResultsError, fn -> MediaLibrary.get_song!(expired_song_2.id) end
      assert active_song == MediaLibrary.get_song!(active_song.id)
    end

    test "Users song_count is decremented when user songs are deleted", %{
      creation_dates: creation_dates
    } do
      user = user_fixture()

      songs_changesets =
        ["1", "2", "3"]
        |> Enum.reduce(%{}, fn song_number, acc ->
          song_changeset =
            Song.changeset(%Song{}, %{title: "song#{song_number}", artist: "artist_one"})

          Map.put_new(acc, song_number, song_changeset)
        end)

      assert {:ok, results} =
               MediaLibrary.import_songs(user, songs_changesets, fn one, two -> {one, two} end)

      assert Accounts.get_user(user.id).songs_count == 3

      created_songs = Enum.reduce(results, [], fn {_key, song}, acc -> [song | acc] end)

      for {song, date} <- Enum.zip(created_songs, creation_dates) do
        song
        |> Ecto.Changeset.change(inserted_at: date)
        |> LiveBeats.Repo.update()
      end

      MediaLibrary.expire_songs_older_than(2, :month)

      assert Accounts.get_user(user.id).songs_count == 1
    end

    defp add_n_months(datetime, n) do
      seconds = 30 * (60 * 60 * 24) * n

      datetime
      |> DateTime.add(seconds, :second)
      |> DateTime.to_naive()
      |> NaiveDateTime.truncate(:second)
    end
  end
end
