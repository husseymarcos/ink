defmodule InkWeb.PageControllerTest do
  use InkWeb.ConnCase

  test "GET / redirects to a room and room page renders the canvas LiveView", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) =~ "/room/"
    room_path = redirected_to(conn)
    conn = get(conn, room_path)
    html = html_response(conn, 200)
    assert html =~ "Real-time canvas"
    assert html =~ "ink-canvas"
    assert html =~ "phx-hook=\"CanvasDraw\""
  end
end
