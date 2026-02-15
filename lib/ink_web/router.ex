defmodule InkWeb.Router do
  use InkWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {InkWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", InkWeb do
    pipe_through :browser

    live "/", CanvasLive, :index
    live "/room/:room_id", CanvasLive, :room
  end

  if Application.compile_env(:ink, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: InkWeb.Telemetry
    end
  end
end
