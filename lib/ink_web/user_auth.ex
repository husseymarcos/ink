defmodule InkWeb.UserAuth do
  use InkWeb, :verified_routes

  import Plug.Conn

  alias Ink.Accounts

  @user_session_key :user_id

  def init(opts), do: opts
  def call(conn, opts), do: fetch_current_user(conn, opts)

  def log_in_user(conn, user) do
    conn
    |> renew_session()
    |> put_session(@user_session_key, user.id)
    |> Phoenix.Controller.redirect(to: ~p"/")
  end

  def log_out_user(conn) do
    configure_session(conn, drop: true)
  end

  def fetch_current_user(conn, _opts) do
    user =
      conn
      |> get_session(@user_session_key)
      |> Accounts.get_user()

    assign(conn, :current_user, user)
  end

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont,
     Phoenix.Component.assign_new(socket, :current_user, fn -> user_from_session(session) end)}
  end

  def on_mount(:require_authenticated_user, _params, session, socket) do
    current_user = user_from_session(session)

    if current_user do
      {:cont, Phoenix.Component.assign(socket, :current_user, current_user)}
    else
      {:halt,
       socket
       |> Phoenix.LiveView.put_flash(:error, "Inicia sesión para continuar.")
       |> Phoenix.LiveView.redirect(to: ~p"/login")}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    if user_from_session(session) do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    else
      {:cont, socket}
    end
  end

  defp user_from_session(%{"user_id" => user_id}), do: Accounts.get_user(user_id)
  defp user_from_session(_), do: nil

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
