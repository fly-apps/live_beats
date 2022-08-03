defmodule LiveBeats.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveBeats.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def user_fixture(attrs \\ %{}) do
    primary_email = attrs[:email] || unique_user_email()

    info = %{
      "avatar_url" => "https://avatars3.githubusercontent.com/u/576796?v=4",
      "bio" => nil,
      "blog" => "chrismccord.com",
      "company" => nil,
      "created_at" => "2010-01-21T16:12:29Z",
      "email" => nil,
      "events_url" => "https://api.github.com/users/chrismccord/events{/privacy}",
      "followers" => 100,
      "followers_url" => "https://api.github.com/users/chrismccord/followers",
      "following" => 100,
      "following_url" => "https://api.github.com/users/chrismccord/following{/other_user}",
      "gists_url" => "https://api.github.com/users/chrismccord/gists{/gist_id}",
      "gravatar_id" => "",
      "hireable" => nil,
      "html_url" => "https://github.com/chrismccord",
      "id" => 1234,
      "location" => "Charlotte, NC",
      "login" => attrs[:username] || "chrismccord",
      "name" => "Chris McCord",
      "node_id" => "slkdfjsklfjsf",
      "organizations_url" => "https://api.github.com/users/chrismccord/orgs",
      "public_gists" => 1,
      "public_repos" => 100,
      "received_events_url" => "https://api.github.com/users/chrismccord/received_events",
      "repos_url" => "https://api.github.com/users/chrismccord/repos",
      "site_admin" => false,
      "starred_url" => "https://api.github.com/users/chrismccord/starred{/owner}{/repo}",
      "subscriptions_url" => "https://api.github.com/users/chrismccord/subscriptions",
      "twitter_username" => nil,
      "type" => "User",
      "updated_at" => "2020-09-18T19:34:45Z",
      "url" => "https://api.github.com/users/chrismccord"
    }

    emails = []
    token = "token"

    {:ok, user} = LiveBeats.Accounts.register_github_user(primary_email, info, emails, token)

    user
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end
end
