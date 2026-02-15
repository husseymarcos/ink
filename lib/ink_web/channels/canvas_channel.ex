defmodule InkWeb.CanvasChannel do
  use Phoenix.Channel

  @impl true
  def join("canvas:room:" <> room_id, _params, socket) do
    socket = assign(socket, :room_id, room_id)
    points = Ink.CanvasStore.get_points(room_id)
    {:ok, %{"points" => points}, socket}
  end

  @impl true
  def handle_in("draw", %{"x" => x, "y" => y}, socket) when not is_nil(x) and not is_nil(y) do
    room_id = socket.assigns.room_id
    Ink.CanvasStore.add_point(room_id, x, y)
    broadcast!(socket, "draw_point", %{"x" => x, "y" => y})
    {:noreply, socket}
  end

  def handle_in("draw", _params, socket) do
    {:noreply, socket}
  end
end
