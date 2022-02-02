defmodule LiveBeats.AccountsTest do
  use LiveBeats.DataCase

  import LiveBeats.AccountsFixtures

  alias LiveBeats.Accounts

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %Accounts.User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_github_user/1" do
    test "creates users with valid data" do
      info = %{
        "id" => "github-id",
        "login" => "Chrismccord",
        "avatar_url" => "https://example.com",
        "html_url" => "https://example.com"
      }

      assert {:ok, _user} = Accounts.register_github_user("chris@example.com", info, [], "123")
    end
  end
end
