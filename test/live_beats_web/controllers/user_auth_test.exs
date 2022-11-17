defmodule LiveBeatsWeb.UserAuthTest do
  use LiveBeatsWeb.ConnCase, async: true

  alias LiveBeats.Accounts
  alias LiveBeatsWeb.UserAuth
  import LiveBeats.AccountsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, LiveBeatsWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: user_fixture(), conn: conn}
  end

  describe "log_in_user/3" do
    test "stores the user id in the session", %{conn: conn, user: user} do
      conn = UserAuth.log_in_user(conn, user)
      assert id = get_session(conn, :user_id)
      assert get_session(conn, :live_socket_id) == "users_sessions:#{id}"
      assert redirected_to(conn) == "/chrismccord"
      assert Accounts.get_user!(id)
    end

    test "clears everything previously stored in the session", %{conn: conn, user: user} do
      conn = conn |> put_session(:to_be_removed, "value") |> UserAuth.log_in_user(user)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, user: user} do
      conn = conn |> put_session(:user_return_to, "/hello") |> UserAuth.log_in_user(user)
      assert redirected_to(conn) == "/hello"
    end
  end

  describe "logout_user/1" do
    test "erases session and cookies", %{conn: conn} do
      conn =
        conn
        |> put_session(:user_id, "123")
        |> fetch_cookies()
        |> UserAuth.log_out_user()

      refute get_session(conn, :user_id)
      assert redirected_to(conn) == "/signin"
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "users_sessions:abcdef-token"
      LiveBeatsWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> UserAuth.log_out_user()

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "users_sessions:abcdef-token"
      }
    end
  end

  describe "fetch_current_user/2" do
    test "authenticates user from session", %{conn: conn, user: user} do
      conn = conn |> put_session(:user_id, user.id) |> UserAuth.fetch_current_user([])
      assert conn.assigns.current_user.id == user.id
    end
  end

  describe "redirect_if_user_is_authenticated/2" do
    test "redirects if user is authenticated", %{conn: conn, user: user} do
      conn = conn |> assign(:current_user, user) |> UserAuth.redirect_if_user_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == LiveBeatsWeb.CoreComponents.profile_path(user)
    end

    test "does not redirect if user is not authenticated", %{conn: conn} do
      conn = UserAuth.redirect_if_user_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_user/2" do
    test "redirects if user is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> UserAuth.require_authenticated_user([])
      assert conn.halted
      assert redirected_to(conn)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | request_path: "/foo", query_string: ""}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :user_return_to) == "/foo"

      halted_conn =
        %{conn | request_path: "/foo", query_string: "bar=baz"}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :user_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | request_path: "/foo?bar", method: "POST"}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_conn.halted
      refute get_session(halted_conn, :user_return_to)
    end

    test "does not redirect if user is authenticated", %{conn: conn, user: user} do
      conn = conn |> assign(:current_user, user) |> UserAuth.require_authenticated_user([])
      refute conn.halted
      refute conn.status
    end
  end
end
