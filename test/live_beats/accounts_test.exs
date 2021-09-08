defmodule LiveBeats.AccountsTest do
  use LiveBeats.DataCase

  alias LiveBeats.Accounts
  import LiveBeats.AccountsFixtures
  alias LiveBeats.Accounts.{User}

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_github_user/1" do
    test "creates users with valid data" do
      flunk "TODO"
    end
  end
end
