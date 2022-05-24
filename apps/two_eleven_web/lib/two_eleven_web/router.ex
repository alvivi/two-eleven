defmodule TwoElevenWeb.Router do
  use TwoElevenWeb, :router

  import TwoElevenWeb.Auth, only: [fetch_current_player: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TwoElevenWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TwoElevenWeb do
    pipe_through [:browser, :fetch_current_player]

    get "/", PageController, :index

    live_session :default, on_mount: TwoElevenWeb.Auth do
      live "/games", GamesLive, :index
      live "/games/new", GamesLive, :new
      live "/games/:id", GamesLive, :show
    end
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TwoElevenWeb.Telemetry
    end
  end
end
