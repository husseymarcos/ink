defmodule InkWeb.UserAuth do
  use InkWeb, :verified_routes

  import Plug.Conn

  alias Ink.Accounts

  @user_session_key :user_id
  @session_establish_salt "ink_lv_session_establish"

  def init(opts), do: opts
  def call(conn, opts), do: fetch_current_user(conn, opts)

  def put_authenticated_session(conn, user, opts \\ []) do
    remember? = Keyword.get(opts, :remember, false)

    conn
    |> renew_session()
    |> configure_session(max_age: session_cookie_max_age(remember?))
    |> put_session(@user_session_key, user.id)
  end

  defp session_cookie_max_age(true), do: 60 * 60 * 24 * 30
  defp session_cookie_max_age(false), do: nil

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

  def sign_session_establish_token(user_id, remember, kind \\ "login")
      when is_binary(user_id) and is_boolean(remember) and kind in ["login", "register"] do
    Phoenix.Token.sign(
      InkWeb.Endpoint,
      @session_establish_salt,
      %{"uid" => user_id, "rem" => remember, "kind" => kind},
      max_age: 60
    )
  end

  def verify_session_establish_token(token) when is_binary(token) do
    case Phoenix.Token.verify(InkWeb.Endpoint, @session_establish_salt, token, max_age: 60) do
      {:ok, %{"uid" => user_id, "rem" => rem, "kind" => kind}} ->
        {:ok, user_id, truthy_remember?(rem), kind}

      {:ok, %{"uid" => user_id, "rem" => rem}} ->
        {:ok, user_id, truthy_remember?(rem), "login"}

      _ ->
        :error
    end
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
       |> Phoenix.LiveView.put_flash(:error, "Sign in to continue.")
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

  defp truthy_remember?(v) when v in [true, "true"], do: true
  defp truthy_remember?(_), do: false

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
