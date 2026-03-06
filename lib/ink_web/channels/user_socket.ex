defmodule InkWeb.UserSocket do
  use Phoenix.Socket

  alias Ink.Accounts

  channel "canvas:room:*", InkWeb.CanvasChannel

  @impl true
  def connect(_params, socket, %{session: %{"user_id" => user_id}}) do
    case Accounts.get_user(user_id) do
      nil -> :error
      user -> {:ok, assign(socket, :current_user, user)}
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "users_socket:#{socket.assigns.current_user.id}"
end
