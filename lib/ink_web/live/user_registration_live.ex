defmodule InkWeb.UserRegistrationLive do
  use InkWeb, :live_view

  alias Ink.Accounts
  alias InkWeb.UserAuth

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Create account")
     |> assign(:form, to_form(%{}, as: :user))}
  end

  @impl true
  def handle_event("register", %{"user" => params}, socket) do
    case Accounts.register_user(params) do
      {:ok, user} ->
        token = UserAuth.sign_session_establish_token(user.id, false, "register")

        {:noreply,
         redirect(socket,
           to: "/session/establish?" <> URI.encode_query(%{token: token})
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :user))}
    end
  end
end
