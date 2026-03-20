defmodule InkWeb.UserSessionController do
  use InkWeb, :controller

  alias Ink.Accounts
  alias InkWeb.UserAuth

  def establish(conn, %{"token" => token}) do
    case UserAuth.verify_session_establish_token(token) do
      {:ok, user_id, remember, kind} ->
        case Accounts.get_user(user_id) do
          nil ->
            conn
            |> put_flash(:error, "Invalid or expired session link.")
            |> redirect(to: ~p"/login")

          user ->
            info =
              case kind do
                "register" -> "Account created successfully."
                _ -> "Welcome back."
              end

            conn
            |> UserAuth.put_authenticated_session(user, remember: remember)
            |> put_flash(:info, info)
            |> redirect(to: ~p"/")
        end

      :error ->
        conn
        |> put_flash(:error, "Invalid or expired session link.")
        |> redirect(to: ~p"/login")
    end
  end

  def establish(conn, _params) do
    conn
    |> put_flash(:error, "Invalid or expired session link.")
    |> redirect(to: ~p"/login")
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
    |> put_flash(:info, "Signed out.")
    |> redirect(to: ~p"/login")
  end
end
