defmodule LiveBeatsWeb.GithubCallbackTest do
  use LiveBeatsWeb.ConnCase, async: true

  alias LiveBeats.Accounts

  def exchange_access_token(opts) do
    _code = opts[:code]
    state = opts[:state]

    case state do
      "valid" ->
        {:ok,
         %{
           info: %{"login" => "chrismccord", "name" => "Chris", "id" => 1},
           primary_email: "chris@local.test",
           emails: [%{"primary" => true, "email" => "chris@local.test"}],
           token: "1234"
         }}

      "invalid" ->
        {:ok,
         %{
           info: %{"login" => "chrismccord"},
           primary_email: "chris@local.test",
           emails: [%{"primary" => true, "email" => "chris@local.test"}],
           token: "1234"
         }}


      "failed" ->
        {:error, %{reason: state}}
    end
  end

  setup %{conn: conn} do
    conn = assign(conn, :github_client, __MODULE__)

    {:ok, conn: conn}
  end

  test "callback with valid token", %{conn: conn} do
    params = %{"code" => "66e1c4202275d071eced", "state" => "valid"}

    assert Accounts.get_user_by_email("chris@local.test") == nil

    conn = get(conn, Routes.o_auth_callback_path(conn, :new, "github", params))

    assert redirected_to(conn, 302) == "/"
    assert %Accounts.User{} = user = Accounts.get_user_by_email("chris@local.test")
    assert user.name == "Chris"
  end

  test "callback with invalid exchange response", %{conn: conn} do
    params = %{"code" => "66e1c4202275d071eced", "state" => "invalid"}
    assert Accounts.list_users(limit: 100) == []

    conn = get(conn, Routes.o_auth_callback_path(conn, :new, "github", params))

    assert get_flash(conn, :error) == "We were unable to fetch the necessary information from your GithHub account"
    assert redirected_to(conn, 302) == "/"
    assert Accounts.list_users(limit: 100) == []
  end

  test "callback with failed token exchange", %{conn: conn} do
    params = %{"code" => "66e1c4202275d071eced", "state" => "failed"}

    assert Accounts.list_users(limit: 100) == []

    conn = get(conn, Routes.o_auth_callback_path(conn, :new, "github", params))

    assert get_flash(conn, :error) == "We were unable to contact GitHub. Please try again later"
    assert redirected_to(conn, 302) == "/"
    assert Accounts.list_users(limit: 100) == []
  end
end
