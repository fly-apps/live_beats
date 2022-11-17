defmodule LiveBeatsWeb.Router do
  use LiveBeatsWeb, :router

  import LiveBeatsWeb.UserAuth,
    only: [redirect_if_user_is_authenticated: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LiveBeatsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiveBeatsWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/oauth/callbacks/:provider", OAuthCallbackController, :new
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: LiveBeatsWeb.Telemetry
    end
  end

  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", LiveBeatsWeb do
    pipe_through :browser

    get "/", RedirectController, :redirect_authenticated
    get "/files/:id", FileController, :show

    delete "/signout", OAuthCallbackController, :sign_out

    live_session :default, on_mount: [{LiveBeatsWeb.UserAuth, :current_user}, LiveBeatsWeb.Nav] do
      live "/signin", SignInLive, :index
    end

    live_session :authenticated,
      on_mount: [{LiveBeatsWeb.UserAuth, :ensure_authenticated}, LiveBeatsWeb.Nav] do
      live "/:profile_username/songs/new", ProfileLive, :new
      live "/:profile_username", ProfileLive, :show
      live "/profile/settings", SettingsLive, :edit
    end
  end
end
