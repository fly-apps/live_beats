defmodule LiveBeats.MediaLibraryTest do
  use LiveBeats.DataCase

  alias LiveBeats.MediaLibrary

  describe "songs" do
    alias LiveBeats.MediaLibrary.Song

    import LiveBeats.AccountsFixtures
    import LiveBeats.MediaLibraryFixtures

    @invalid_attrs %{album_artist: nil, artist: nil, date_recorded: nil, date_released: nil, duration: nil, title: nil}

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
      update_attrs = %{album_artist: "some updated album_artist", artist: "some updated artist", date_recorded: ~N[2021-10-27 20:11:00], date_released: ~N[2021-10-27 20:11:00], duration: 43, title: "some updated title"}

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

    test "delete_song/1 deletes the song" do
      user = user_fixture()
      song = song_fixture(%{user_id: user.id})
      assert :ok = MediaLibrary.delete_song(song)
      assert_raise Ecto.NoResultsError, fn -> MediaLibrary.get_song!(song.id) end
    end

    test "change_song/1 returns a song changeset" do
      song = song_fixture()
      assert %Ecto.Changeset{} = MediaLibrary.change_song(song)
    end
  end
end
