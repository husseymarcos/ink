defmodule InkWeb.UserLoginLive do
  use InkWeb, :live_view

  alias Ink.Accounts
  alias InkWeb.UserAuth

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Sign in")
     |> assign(:form, to_form(%{}, as: :user))}
  end

  @impl true
  def handle_event("login", %{"user" => params}, socket) do
    email = params["email"] || ""
    password = params["password"] || ""
    remember = params["remember_me"] == "true"

    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        token = UserAuth.sign_session_establish_token(user.id, remember, "login")

        {:noreply,
         redirect(socket,
           to: "/session/establish?" <> URI.encode_query(%{token: token})
         )}

      :error ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid email or password.")
         |> assign(:form, to_form(%{"email" => email}, as: :user))}
    end
  end
end
