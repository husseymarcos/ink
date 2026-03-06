defmodule InkWeb.UserSessionController do
  use InkWeb, :controller

  alias Ink.Accounts
  alias InkWeb.UserAuth

  plug :redirect_if_user_is_authenticated when action in [:new, :create]

  def new(conn, _params) do
    form = Phoenix.Component.to_form(%{}, as: :user)
    render(conn, :new, form: form)
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Bienvenido de vuelta.")
        |> UserAuth.log_in_user(user)

      :error ->
        conn
        |> put_flash(:error, "Email o password inválidos.")
        |> render(:new, form: Phoenix.Component.to_form(%{"email" => email}, as: :user))
    end
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
    |> put_flash(:info, "Sesión cerrada.")
    |> redirect(to: ~p"/login")
  end

  defp redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns.current_user do
      conn
      |> redirect(to: ~p"/")
      |> halt()
    else
      conn
    end
  end
end
