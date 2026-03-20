defmodule InkWeb.Router do
  use InkWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug InkWeb.UserAuth, :fetch_current_user
    plug :put_root_layout, html: {InkWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", InkWeb do
    pipe_through :browser

    delete "/logout", UserSessionController, :delete
    get "/session/establish", UserSessionController, :establish

    live_session :public_auth,
      on_mount: [
        {InkWeb.UserAuth, :mount_current_user},
        {InkWeb.UserAuth, :redirect_if_user_is_authenticated}
      ] do
      live "/login", UserLoginLive
      live "/register", UserRegistrationLive
    end

    live_session :authenticated,
      on_mount: [{InkWeb.UserAuth, :require_authenticated_user}] do
      live "/", RoomsLive, :index
      live "/room/:room_id", CanvasLive, :room
    end
  end

  if Application.compile_env(:ink, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: InkWeb.Telemetry
    end
  end
end
