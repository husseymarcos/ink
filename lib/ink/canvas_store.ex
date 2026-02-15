defmodule Ink.CanvasStore do
  use GenServer

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
    {:reply, strokes, state}
  end

  @impl true
  def handle_call({:undo, room_id}, _from, state) do
    case Map.get(state, room_id, []) do
      [] ->
        {:reply, {:error, :empty}, state}

      strokes ->
        {_removed, rest} = List.pop_at(strokes, -1)
        new_state = Map.put(state, room_id, rest)
        {:reply, {:ok, rest}, new_state}
    end
  end

  @impl true
  def handle_cast({:start_stroke, room_id}, state) do
    new_state =
      Map.update(state, room_id, [[]], fn strokes ->
        strokes ++ [[]]
      end)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:add_point, room_id, x, y}, state) do
    point = %{"x" => x, "y" => y}

    new_state =
      Map.update(state, room_id, [[point]], fn strokes ->
        case strokes do
          [] -> [[point]]
          list -> List.update_at(list, -1, &(&1 ++ [point]))
        end
      end)

    {:noreply, new_state}
  end
end
