defmodule LiveBeatsWeb.SettingsLiveTest do
  use LiveBeatsWeb.ConnCase

  # import Phoenix.LiveViewTest
  import LiveBeats.AccountsFixtures

  setup %{conn: conn} do
    current_user = user_fixture(%{username: "chrismccord"})
    user2 = user_fixture(%{username: "mrkurt"})
    conn = log_in_user(conn, current_user)
    {:ok, conn: conn, current_user: current_user, user2: user2}
  end

  # test "updating settings", %{conn: conn, current_user: current_user} do
  #   # TODO
  # end
end
