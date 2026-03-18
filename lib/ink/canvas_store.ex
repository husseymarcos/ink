defmodule Ink.CanvasStore do
  use GenServer

  @undo_window_ms 1000

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def get_strokes(room_id), do: GenServer.call(__MODULE__, {:get_strokes, room_id})

  def get_last_stroke_color(room_id),
    do: GenServer.call(__MODULE__, {:get_last_stroke_color, room_id})

  def start_stroke(room_id, color \\ nil),
    do: GenServer.cast(__MODULE__, {:start_stroke, room_id, color})

  def add_point(room_id, x, y), do: GenServer.cast(__MODULE__, {:add_point, room_id, x, y})

  def undo(room_id), do: GenServer.call(__MODULE__, {:undo, room_id})

  def get_code_blocks(room_id), do: GenServer.call(__MODULE__, {:get_code_blocks, room_id})

  def put_code_block(room_id, code_block_map),
    do: GenServer.cast(__MODULE__, {:put_code_block, room_id, code_block_map})

  def remove_code_block(room_id, code_block_id),
    do: GenServer.cast(__MODULE__, {:remove_code_block, room_id, code_block_id})

  def update_code_block_in_memory(room_id, code_block_map),
    do: GenServer.cast(__MODULE__, {:update_code_block_in_memory, room_id, code_block_map})

  @impl true
  def init(state), do: {:ok, state}

  defp get_room_data(state, room_id) do
    raw = Map.get(state, room_id, %{})

    %{
      strokes: Map.get(raw, :strokes, []),
      texts: Map.get(raw, :texts, []),
      code_blocks: Map.get(raw, :code_blocks, %{})
    }
  end

  defp put_room_data(state, room_id, %{strokes: _, texts: _, code_blocks: _} = data) do
    Map.put(state, room_id, data)
  end

  @impl true
  def handle_call({:get_strokes, room_id}, _from, state) do
    %{strokes: strokes} = get_room_data(state, room_id)
    {:reply, Ink.Canvas.to_points(strokes), state}
  end

  @impl true
  def handle_call({:get_last_stroke_color, room_id}, _from, state) do
    %{strokes: strokes} = get_room_data(state, room_id)

    color =
      case strokes do
        [] -> Ink.Canvas.default_color()
        list -> Map.get(List.last(list), :color, Ink.Canvas.default_color())
      end

    {:reply, color, state}
  end

  @impl true
  def handle_call({:undo, room_id}, _from, state) do
    data = get_room_data(state, room_id)
    kept_strokes = Ink.Canvas.remove_last_time_window(data.strokes, @undo_window_ms)
    new_data = %{data | strokes: kept_strokes}
    new_state = put_room_data(state, room_id, new_data)
    {:reply, {:ok, Ink.Canvas.to_points(kept_strokes)}, new_state}
  end

  @impl true
  def handle_call({:get_code_blocks, room_id}, _from, state) do
    %{code_blocks: code_blocks} = get_room_data(state, room_id)
    {:reply, code_blocks, state}
  end

  @impl true
  def handle_cast({:start_stroke, room_id, color}, state) do
    data = get_room_data(state, room_id)
    new_strokes = Ink.Canvas.start_stroke(data.strokes, color || Ink.Canvas.default_color())
    new_state = put_room_data(state, room_id, %{data | strokes: new_strokes})
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:add_point, room_id, x, y}, state) do
    data = get_room_data(state, room_id)

    strokes =
      if data.strokes == [] do
        Ink.Canvas.add_point(
          [%{points: [], created_at: nil, color: Ink.Canvas.default_color()}],
          x,
          y
        )
      else
        Ink.Canvas.add_point(data.strokes, x, y)
      end

    new_state = put_room_data(state, room_id, %{data | strokes: strokes})
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:put_code_block, room_id, code_block_map}, state) do
    data = get_room_data(state, room_id)
    id = code_block_map["id"]
    new_code_blocks = Map.put(data.code_blocks, id, code_block_map)
    new_state = put_room_data(state, room_id, %{data | code_blocks: new_code_blocks})
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:remove_code_block, room_id, code_block_id}, state) do
    data = get_room_data(state, room_id)
    new_code_blocks = Map.delete(data.code_blocks, code_block_id)
    new_state = put_room_data(state, room_id, %{data | code_blocks: new_code_blocks})
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_code_block_in_memory, room_id, code_block_map}, state) do
    data = get_room_data(state, room_id)
    id = code_block_map["id"]
    new_code_blocks = Map.put(data.code_blocks, id, code_block_map)
    new_state = put_room_data(state, room_id, %{data | code_blocks: new_code_blocks})
    {:noreply, new_state}
  end
end
