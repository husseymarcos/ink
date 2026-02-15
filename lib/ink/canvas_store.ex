defmodule Ink.CanvasStore do
  use GenServer

  @undo_window_ms 1000

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def get_strokes(room_id), do: GenServer.call(__MODULE__, {:get_strokes, room_id})

  def start_stroke(room_id), do: GenServer.cast(__MODULE__, {:start_stroke, room_id})

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
  def handle_call({:undo, room_id}, _from, state) do
    strokes = Map.get(state, room_id, [])
    cutoff = System.system_time(:millisecond) - @undo_window_ms
    kept = Ink.Canvas.remove_strokes_after(strokes, cutoff)
    new_state = Map.put(state, room_id, kept)
    {:reply, {:ok, Ink.Canvas.to_points(kept)}, new_state}
  end

  @impl true
  def handle_cast({:start_stroke, room_id}, state) do
    new_state =
      Map.update(state, room_id, [], fn strokes ->
        Ink.Canvas.start_stroke(strokes)
      end)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:add_point, room_id, x, y}, state) do
    new_state =
      Map.update(state, room_id, [%{points: [], created_at: nil}], fn strokes ->
        Ink.Canvas.add_point(strokes, x, y)
      end)

    {:noreply, new_state}
  end
end
