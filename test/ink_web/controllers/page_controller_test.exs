defmodule InkWeb.PageControllerTest do
  use InkWeb.ConnCase

  alias Ink.Accounts

  test "GET / redirects unauthenticated users to login", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/login"
  end

  test "GET / shows dashboard for authenticated users", %{conn: conn} do
    {:ok, user} =
      Accounts.register_user(%{
        "email" => "canvas@example.com",
        "password" => "supersecret1"
      })

    conn =
      conn
      |> init_test_session(%{})
      |> put_session(:user_id, user.id)
      |> get(~p"/")

    assert conn.status == 200
    assert conn.resp_body =~ "Tus rooms"
  end
end
