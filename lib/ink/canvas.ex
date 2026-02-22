defmodule Ink.Canvas do
  @moduledoc """
  Business logic for canvas strokes: adding points, starting strokes, undo by time window.
  Pure functions over stroke data; no process state.
  """

  @default_color "#3b82f6"

  @doc "Default stroke color used when none is given. Single source of truth for the app."
  def default_color, do: @default_color

  @type stroke :: %{
          required(:points) => [%{required(String.t()) => number()}],
          required(:created_at) => non_neg_integer() | nil,
          optional(:color) => String.t()
        }
  @type strokes :: [stroke()]

  @doc "Append a new empty stroke to the list with the given color (default: #{@default_color})."
  @spec start_stroke(strokes(), String.t()) :: strokes()
  def start_stroke(strokes, color \\ @default_color) do
    strokes ++ [%{points: [], created_at: nil, color: color}]
  end

  @doc "Add point (x, y) to the current strokes. Sets created_at on first point of a stroke."
  @spec add_point(strokes(), number(), number(), non_neg_integer()) :: strokes()
  def add_point(strokes, x, y, now_ms \\ System.system_time(:millisecond)) do
    point = %{"x" => x, "y" => y}

    case strokes do
      [] ->
        [%{points: [point], created_at: now_ms}]

      list ->
        last = List.last(list)

        updated_last =
          if last.created_at == nil do
            %{last | points: last.points ++ [point], created_at: now_ms}
          else
            %{last | points: last.points ++ [point]}
          end

        List.replace_at(list, -1, updated_last)
    end
  end

  @doc "Remove all strokes with created_at >= cutoff_ms (e.g. drawn in the last second)."
  @spec remove_strokes_after(strokes(), non_neg_integer()) :: strokes()
  def remove_strokes_after(strokes, cutoff_ms) do
    Enum.reject(strokes, fn stroke -> stroke_created_after?(stroke, cutoff_ms) end)
  end

  @doc """
  Remove the most recent time window of strokes (e.g. last 1 second of drawing).
  Uses the latest stroke's created_at as reference, so each undo removes the
  previous window (first undo = last 1s, second undo = 1s before that, etc.).
  """
  @spec remove_last_time_window(strokes(), non_neg_integer()) :: strokes()
  def remove_last_time_window(strokes, window_ms) do
    case latest_created_at(strokes) do
      nil -> strokes
      latest -> remove_strokes_after(strokes, latest - window_ms)
    end
  end

  defp latest_created_at(strokes) do
    strokes
    |> Enum.map(& &1.created_at)
    |> Enum.reject(&is_nil/1)
    |> Enum.max(fn -> nil end)
  end

  @doc "Convert internal stroke structs to client format: list of %{points: [...], color: \"#hex\"}."
  @spec to_points(strokes()) :: [%{points: [%{String.t() => number()}], color: String.t()}]
  def to_points(strokes) when is_list(strokes) do
    Enum.map(strokes, fn s ->
      %{points: s.points, color: Map.get(s, :color, @default_color)}
    end)
  end

  defp stroke_created_after?(%{created_at: nil}, _cutoff), do: false
  defp stroke_created_after?(%{created_at: ts}, cutoff), do: ts >= cutoff
end
