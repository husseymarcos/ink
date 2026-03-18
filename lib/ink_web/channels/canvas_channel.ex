defmodule InkWeb.CanvasChannel do
  use Phoenix.Channel

  alias Ink.Collaboration
  alias Ink.CodeBlocks
  alias InkWeb.Presence

  @impl true
  def join("canvas:room:" <> room_slug, _params, %{assigns: %{current_user: user}} = socket) do
    case Collaboration.get_room_by_slug(room_slug) do
      nil ->
        {:error, %{reason: "room_not_found"}}

      room ->
        if Collaboration.user_has_access?(room, user) do
          socket = assign(socket, :room_id, room_slug)
          room_id = room.id

          {:ok, _} =
            Presence.track(socket, user.id, %{
              email: user.email,
              joined_at: System.system_time(:millisecond)
            })

          strokes = Ink.CanvasStore.get_strokes(room_slug)
          code_blocks = load_code_blocks(room_id)
          {:ok, %{"strokes" => strokes, "code_blocks" => code_blocks}, socket}
        else
          {:error, %{reason: "forbidden"}}
        end
    end
  end

  def join("canvas:room:" <> _room_slug, _params, _socket) do
    {:error, %{reason: "unauthenticated"}}
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
    room_id = socket.assigns.room_id

    case Ink.CanvasStore.undo(room_id) do
      {:ok, strokes} ->
        broadcast!(socket, "strokes_replaced", %{"strokes" => strokes})
        {:reply, {:ok, %{}}, socket}

      {:error, :empty} ->
        {:reply, {:ok, %{}}, socket}
    end
  end

  @impl true
  def handle_in("code_block_insert", params, socket) do
    room_id = socket.assigns.room_id
    room = Collaboration.get_room_by_slug(room_id)

    case CodeBlocks.create_code_block(Map.put(params, "room_id", room.id)) do
      {:ok, code_block} ->
        code_block_map = CodeBlocks.to_map(code_block)
        Ink.CanvasStore.put_code_block(room_id, code_block_map)
        broadcast!(socket, "code_block_inserted", code_block_map)
        {:reply, {:ok, code_block_map}, socket}

      {:error, _} ->
        {:reply, {:error, %{reason: "failed_to_create"}}, socket}
    end
  end

  @impl true
  def handle_in("code_block_update", %{"id" => id, "code" => code}, socket) do
    room_id = socket.assigns.room_id

    case CodeBlocks.get_code_block(id) do
      nil ->
        {:reply, {:error, %{reason: "not_found"}}, socket}

      code_block ->
        case CodeBlocks.update_content(code_block, code) do
          {:ok, updated} ->
            code_block_map = CodeBlocks.to_map(updated)
            Ink.CanvasStore.update_code_block_in_memory(room_id, code_block_map)
            broadcast!(socket, "code_block_updated", code_block_map)
            {:reply, {:ok, code_block_map}, socket}

          {:error, _} ->
            {:reply, {:error, %{reason: "failed_to_update"}}, socket}
        end
    end
  end

  @impl true
  def handle_in("code_block_move", %{"id" => id, "x" => x, "y" => y}, socket) do
    room_id = socket.assigns.room_id

    case CodeBlocks.get_code_block(id) do
      nil ->
        {:reply, {:error, %{reason: "not_found"}}, socket}

      code_block ->
        case CodeBlocks.update_position(code_block, x, y) do
          {:ok, updated} ->
            code_block_map = CodeBlocks.to_map(updated)
            Ink.CanvasStore.update_code_block_in_memory(room_id, code_block_map)
            broadcast!(socket, "code_block_moved", code_block_map)
            {:reply, {:ok, code_block_map}, socket}

          {:error, _} ->
            {:reply, {:error, %{reason: "failed_to_move"}}, socket}
        end
    end
  end

  @impl true
  def handle_in("code_block_resize", %{"id" => id, "width" => width}, socket) do
    room_id = socket.assigns.room_id

    case CodeBlocks.get_code_block(id) do
      nil ->
        {:reply, {:error, %{reason: "not_found"}}, socket}

      code_block ->
        case CodeBlocks.update_width(code_block, width) do
          {:ok, updated} ->
            code_block_map = CodeBlocks.to_map(updated)
            Ink.CanvasStore.update_code_block_in_memory(room_id, code_block_map)
            broadcast!(socket, "code_block_resized", code_block_map)
            {:reply, {:ok, code_block_map}, socket}

          {:error, _} ->
            {:reply, {:error, %{reason: "failed_to_resize"}}, socket}
        end
    end
  end

  @impl true
  def handle_in("code_block_delete", %{"id" => id}, socket) do
    room_id = socket.assigns.room_id

    case CodeBlocks.get_code_block(id) do
      nil ->
        {:reply, {:error, %{reason: "not_found"}}, socket}

      code_block ->
        case CodeBlocks.delete_code_block(code_block) do
          {:ok, _} ->
            Ink.CanvasStore.remove_code_block(room_id, id)
            broadcast!(socket, "code_block_deleted", %{"id" => id})
            {:reply, {:ok, %{}}, socket}

          {:error, _} ->
            {:reply, {:error, %{reason: "failed_to_delete"}}, socket}
        end
    end
  end

  @impl true
  def handle_in("code_block_language", %{"id" => id, "language" => language}, socket) do
    room_id = socket.assigns.room_id

    case CodeBlocks.get_code_block(id) do
      nil ->
        {:reply, {:error, %{reason: "not_found"}}, socket}

      code_block ->
        case CodeBlocks.update_language(code_block, language) do
          {:ok, updated} ->
            code_block_map = CodeBlocks.to_map(updated)
            Ink.CanvasStore.update_code_block_in_memory(room_id, code_block_map)
            broadcast!(socket, "code_block_language_changed", code_block_map)
            {:reply, {:ok, code_block_map}, socket}

          {:error, _} ->
            {:reply, {:error, %{reason: "failed_to_change_language"}}, socket}
        end
    end
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

  defp load_code_blocks(room_id) do
    room_id
    |> CodeBlocks.get_code_blocks_by_room()
    |> Enum.map(&CodeBlocks.to_map/1)
  end

  defp stroke_start?([]), do: true

  defp stroke_start?(strokes) do
    last = List.last(strokes)
    last == nil or last.points == []
  end
end
