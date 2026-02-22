defmodule InkWeb.CanvasChannel do
  use Phoenix.Channel

  @impl true
  def join("canvas:room:" <> room_id, _params, socket) do
    socket = assign(socket, :room_id, room_id)
    strokes = Ink.CanvasStore.get_strokes(room_id)
    {:ok, %{"strokes" => strokes}, socket}
  end

  @impl true
  def handle_in("start_stroke", params, socket) do
    room_id = socket.assigns.room_id
    color = params["color"]
    Ink.CanvasStore.start_stroke(room_id, color)
    {:noreply, socket}
  end

  @impl true
  def handle_in("draw", %{"x" => x, "y" => y}, socket) when not is_nil(x) and not is_nil(y) do
    room_id = socket.assigns.room_id
    strokes = Ink.CanvasStore.get_strokes(room_id)
    stroke_start = stroke_start?(strokes)
    Ink.CanvasStore.add_point(room_id, x, y)
    color = Ink.CanvasStore.get_last_stroke_color(room_id)

    broadcast!(socket, "draw_point", %{
      "x" => x,
      "y" => y,
      "stroke_start" => stroke_start,
      "color" => color
    })

    {:noreply, socket}
  end

  def handle_in("draw", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_in("undo", _params, socket) do
    room_id = socket.assigns.room_id

    case Ink.CanvasStore.undo(room_id) do
      {:ok, strokes} ->
        broadcast!(socket, "strokes_replaced", %{"strokes" => strokes})
        {:reply, {:ok, %{}}, socket}

      {:error, :empty} ->
        {:reply, {:ok, %{}}, socket}
    end
  end

  defp stroke_start?([]), do: true

  defp stroke_start?(strokes) do
    last = List.last(strokes)
    last == nil or last.points == []
  end
end
