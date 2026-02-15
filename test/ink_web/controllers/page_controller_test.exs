defmodule InkWeb.PageControllerTest do
  use InkWeb.ConnCase

  test "GET / renders the canvas LiveView", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)
    assert html =~ "Real-time canvas"
    assert html =~ "ink-canvas"
    assert html =~ "phx-hook=\"CanvasDraw\""
  end
end
