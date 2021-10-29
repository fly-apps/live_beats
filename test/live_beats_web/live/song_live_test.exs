defmodule LiveBeatsWeb.SongLiveTest do
  use LiveBeatsWeb.ConnCase

  import Phoenix.LiveViewTest
  import LiveBeats.MediaLibraryFixtures

  @create_attrs %{album_artist: "some album_artist", artist: "some artist", date_recorded: %{day: 26, hour: 20, minute: 11, month: 10, year: 2021}, date_released: %{day: 26, hour: 20, minute: 11, month: 10, year: 2021}, duration: 42, title: "some title"}
  @update_attrs %{album_artist: "some updated album_artist", artist: "some updated artist", date_recorded: %{day: 27, hour: 20, minute: 11, month: 10, year: 2021}, date_released: %{day: 27, hour: 20, minute: 11, month: 10, year: 2021}, duration: 43, title: "some updated title"}
  @invalid_attrs %{album_artist: nil, artist: nil, date_recorded: %{day: 30, hour: 20, minute: 11, month: 2, year: 2021}, date_released: %{day: 30, hour: 20, minute: 11, month: 2, year: 2021}, duration: nil, title: nil}

  defp create_song(_) do
    song = song_fixture()
    %{song: song}
  end

  describe "Index" do
    setup [:create_song]

    test "lists all songs", %{conn: conn, song: song} do
      {:ok, _index_live, html} = live(conn, Routes.song_index_path(conn, :index))

      assert html =~ "Listing Songs"
      assert html =~ song.album_artist
    end

    test "saves new song", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.song_index_path(conn, :index))

      assert index_live |> element("a", "New Song") |> render_click() =~
               "New Song"

      assert_patch(index_live, Routes.song_index_path(conn, :new))

      assert index_live
             |> form("#song-form", song: @invalid_attrs)
             |> render_change() =~ "is invalid"

      {:ok, _, html} =
        index_live
        |> form("#song-form", song: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.song_index_path(conn, :index))

      assert html =~ "Song created successfully"
      assert html =~ "some album_artist"
    end

    test "updates song in listing", %{conn: conn, song: song} do
      {:ok, index_live, _html} = live(conn, Routes.song_index_path(conn, :index))

      assert index_live |> element("#song-#{song.id} a", "Edit") |> render_click() =~
               "Edit Song"

      assert_patch(index_live, Routes.song_index_path(conn, :edit, song))

      assert index_live
             |> form("#song-form", song: @invalid_attrs)
             |> render_change() =~ "is invalid"

      {:ok, _, html} =
        index_live
        |> form("#song-form", song: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.song_index_path(conn, :index))

      assert html =~ "Song updated successfully"
      assert html =~ "some updated album_artist"
    end

    test "deletes song in listing", %{conn: conn, song: song} do
      {:ok, index_live, _html} = live(conn, Routes.song_index_path(conn, :index))

      assert index_live |> element("#song-#{song.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#song-#{song.id}")
    end
  end

  describe "Show" do
    setup [:create_song]

    test "displays song", %{conn: conn, song: song} do
      {:ok, _show_live, html} = live(conn, Routes.song_show_path(conn, :show, song))

      assert html =~ "Show Song"
      assert html =~ song.album_artist
    end

    test "updates song within modal", %{conn: conn, song: song} do
      {:ok, show_live, _html} = live(conn, Routes.song_show_path(conn, :show, song))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Song"

      assert_patch(show_live, Routes.song_show_path(conn, :edit, song))

      assert show_live
             |> form("#song-form", song: @invalid_attrs)
             |> render_change() =~ "is invalid"

      {:ok, _, html} =
        show_live
        |> form("#song-form", song: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.song_show_path(conn, :show, song))

      assert html =~ "Song updated successfully"
      assert html =~ "some updated album_artist"
    end
  end
end
