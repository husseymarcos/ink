defmodule InkWeb.PageController do
  use InkWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
