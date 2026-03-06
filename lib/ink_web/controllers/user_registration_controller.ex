defmodule InkWeb.UserRegistrationController do
  use InkWeb, :controller

  alias Ink.Accounts
  alias InkWeb.UserAuth

  plug :redirect_if_user_is_authenticated when action in [:new, :create]

  def new(conn, _params) do
    form = Phoenix.Component.to_form(%{}, as: :user)
    render(conn, :new, form: form)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Cuenta creada correctamente.")
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, :new, form: Phoenix.Component.to_form(changeset, as: :user))
    end
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
