# LiveBeats

Play music together with Phoenix LiveView!

Visit [livebeats.fly.dev](http://livebeats.fly.dev) to try it out, or run locally:

  * Create a [Github OAuth app](https://docs.github.com/en/developers/apps/building-oauth-apps/creating-an-oauth-app) from [this page](https://github.com/settings/applications/new)
    - Set the app homepage to `http://localhost:4000` and `Authorization callback URL` to `http://localhost:4000/oauth/callbacks/github`
    - After completing the form, click "Generate a new client secret" to obtain your API secret
  * Export your GitHub Client ID and secret:

        export LIVE_BEATS_GITHUB_CLIENT_ID="..."
        export LIVE_BEATS_GITHUB_CLIENT_SECRET="..."

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
