defmodule InkWeb.CanvasChannel do
  use Phoenix.Channel

  @impl true
  def join("canvas:shared", _params, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_in("draw", %{"x" => x, "y" => y}, socket) when not is_nil(x) and not is_nil(y) do
    broadcast!(socket, "draw_point", %{"x" => x, "y" => y})
    {:noreply, socket}
  end

  def handle_in("draw", _params, socket) do
    {:noreply, socket}
  end
end
