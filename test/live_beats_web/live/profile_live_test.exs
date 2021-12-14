defmodule LiveBeatsWeb.ProfileLiveTest do
  use LiveBeatsWeb.ConnCase

  import Phoenix.LiveViewTest
  import LiveBeats.AccountsFixtures

  alias LiveBeats.MediaLibrary
  alias LiveBeatsWeb.LiveHelpers

  setup %{conn: conn} do
    current_user = user_fixture(%{username: "chrismccord"})
    user2 = user_fixture(%{username: "mrkurt"})
    conn = log_in_user(conn, current_user)
    {:ok, conn: conn, current_user: current_user, user2: user2}
  end

  describe "own profile" do
    test "profile page uploads", %{conn: conn, current_user: current_user} do
      profile = MediaLibrary.get_profile!(current_user)
      {:ok, lv, dead_html} = live(conn, LiveHelpers.profile_path(current_user))

      assert dead_html =~ "chrismccord&#39;s beats"

      # uploads
      assert lv
            |> element("#upload-btn")
            |> render_click()

      assert render(lv) =~ "Add Songs"

      mp3 =
        file_input(lv, "#song-form", :mp3, [
          %{
            last_modified: 1_594_171_879_000,
            name: "my.mp3",
            content: File.read!("test/support/fixtures/silence1s.mp3"),
            type: "audio/mpeg"
          }
        ])

      assert render_upload(mp3, "my.mp3") =~ "can&#39;t be blank"

      [%{"ref" => ref}] = mp3.entries

      refute lv
            |> form("#song-form")
            |> render_change(%{
              "_target" => ["songs", ref, "artist"],
              "songs" => %{
                ref => %{"artist" => "Anon", "attribution" => "", "title" => "silence1s"}
              }
            }) =~ "can&#39;t be blank"

      assert {:ok, new_lv, html} =
              lv |> form("#song-form") |> render_submit() |> follow_redirect(conn)

      assert_redirected(lv, "/#{current_user.username}")
      assert html =~ "1 song(s) uploaded"

      assert html =~ "silence1s"

      # deleting songs

      song = MediaLibrary.get_first_song(profile)
      assert new_lv |> element("#delete-modal-#{song.id}-confirm") |> render_click()

      {:ok, refreshed_lv, _} = live(conn, LiveHelpers.profile_path(current_user))
      refute render(refreshed_lv) =~ "silence1s"
    end

    test "invalid uploads" do
      # TODO
    end
  end

  describe "viewing other profiles" do
    # TODO
  end
end
