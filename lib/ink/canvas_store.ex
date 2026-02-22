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

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:get_strokes, room_id}, _from, state) do
    strokes = Map.get(state, room_id, [])
    {:reply, Ink.Canvas.to_points(strokes), state}
  end

  @impl true
  def handle_call({:get_last_stroke_color, room_id}, _from, state) do
    color =
      case Map.get(state, room_id, []) do
        [] -> Ink.Canvas.default_color()
        strokes -> Map.get(List.last(strokes), :color, Ink.Canvas.default_color())
      end

    {:reply, color, state}
  end

  @impl true
  def handle_call({:undo, room_id}, _from, state) do
    strokes = Map.get(state, room_id, [])
    kept = Ink.Canvas.remove_last_time_window(strokes, @undo_window_ms)
    new_state = Map.put(state, room_id, kept)
    {:reply, {:ok, Ink.Canvas.to_points(kept)}, new_state}
  end

  @impl true
  def handle_cast({:start_stroke, room_id, color}, state) do
    new_state =
      Map.update(state, room_id, [], fn strokes ->
        Ink.Canvas.start_stroke(strokes, color || Ink.Canvas.default_color())
      end)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:add_point, room_id, x, y}, state) do
    new_state =
      Map.update(
        state,
        room_id,
        [%{points: [], created_at: nil, color: Ink.Canvas.default_color()}],
        fn strokes ->
          Ink.Canvas.add_point(strokes, x, y)
        end
      )

    {:noreply, new_state}
  end
end
