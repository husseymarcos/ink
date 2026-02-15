defmodule Ink.CanvasStore do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def get_points(room_id), do: GenServer.call(__MODULE__, {:get, room_id})

  def add_point(room_id, x, y), do: GenServer.cast(__MODULE__, {:add, room_id, x, y})

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:get, room_id}, _from, state) do
    {:reply, Map.get(state, room_id, []), state}
  end

  @impl true
  def handle_cast({:add, room_id, x, y}, state) do
    new_state = Map.update(state, room_id, [%{"x" => x, "y" => y}], fn list ->
      list ++ [%{"x" => x, "y" => y}]
    end)
    {:noreply, new_state}
  end
end
