defmodule InkWeb.CanvasChannel do
  use Phoenix.Channel

  alias Ink.Collaboration
  alias Ink.RoomState
  alias InkWeb.Presence

  @impl true
  def join("canvas:room:" <> room_slug, _params, %{assigns: %{current_user: user}} = socket) do
    case Collaboration.get_room_by_slug(room_slug) do
      nil ->
        {:error, %{reason: "room_not_found"}}

      room ->
        if Collaboration.user_has_access?(room, user) do
          socket = assign(socket, :room_id, room_slug)

          {:ok, _} =
            Presence.track(socket, user.id, %{
              email: user.email,
              joined_at: System.system_time(:millisecond)
            })

          state = RoomState.get_room_state(room_slug)
          {:ok, %{"strokes" => state.strokes, "code_blocks" => state.code_blocks}, socket}
        else
          {:error, %{reason: "forbidden"}}
        end
    end
  end

  def join("canvas:room:" <> _room_slug, _params, _socket) do
    {:error, %{reason: "unauthenticated"}}
  end

  @impl true
  def handle_in("start_stroke", %{"color" => color}, socket) do
    RoomState.start_stroke(socket.assigns.room_id, color)
    {:noreply, socket}
  end

  def handle_in("start_stroke", _params, socket) do
    RoomState.start_stroke(socket.assigns.room_id, nil)
    {:noreply, socket}
  end

  @impl true
  def handle_in("draw", %{"x" => x, "y" => y}, socket) when not is_nil(x) and not is_nil(y) do
    room_id = socket.assigns.room_id
    strokes = Ink.CanvasStore.get_strokes(room_id)
    stroke_start = stroke_start?(strokes)
    RoomState.add_point(room_id, x, y)
    color = Ink.CanvasStore.get_last_stroke_color(room_id)

    broadcast_from!(socket, "draw_point", %{
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
  def handle_in(
        "cursor_move",
        %{"x" => x, "y" => y},
        %{assigns: %{current_user: user}} = socket
      )
      when not is_nil(x) and not is_nil(y) do
    broadcast_from!(socket, "cursor_position", %{
      "x" => x,
      "y" => y,
      "user_id" => user.id,
      "email" => user.email
    })

    {:noreply, socket}
  end

  def handle_in("cursor_move", _params, socket) do
    {:noreply, socket}
  end

  def handle_in("undo", _params, socket) do
    {:reply, RoomState.undo_stroke(socket.assigns.room_id), socket}
  end

  @impl true
  def handle_in("code_block_insert", params, socket) do
    {:reply, RoomState.create_code_block(socket.assigns.room_id, params), socket}
  end

  def handle_in("code_block_update", %{"id" => id, "code" => code}, socket) do
    {:reply, RoomState.update_code_block(socket.assigns.room_id, id, %{"code" => code}), socket}
  end

  @impl true
  def handle_in("code_block_move", %{"id" => id, "x" => x, "y" => y}, socket) do
    {:reply, RoomState.move_code_block(socket.assigns.room_id, id, x, y), socket}
  end

  def handle_in("code_block_resize", %{"id" => id, "width" => width}, socket) do
    {:reply, RoomState.resize_code_block(socket.assigns.room_id, id, width), socket}
  end

  def handle_in("code_block_delete", %{"id" => id}, socket) do
    {:reply, RoomState.delete_code_block(socket.assigns.room_id, id), socket}
  end

  def handle_in("code_block_language", %{"id" => id, "language" => language}, socket) do
    {:reply, RoomState.change_language(socket.assigns.room_id, id, language), socket}
  end

  @impl true
  def handle_in("code_block_run", params, %{assigns: %{current_user: user}} = socket) do
    %{"id" => id} = params

    broadcast_from!(socket, "code_block_running", %{
      "id" => id,
      "user_id" => user.id,
      "email" => user.email
    })

    {:reply, {:ok, %{}}, socket}
  end

  defp stroke_start?([]), do: true

  defp stroke_start?(strokes) do
    last = List.last(strokes)
    last == nil or last.points == []
  end
end
