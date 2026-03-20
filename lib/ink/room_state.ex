defmodule Ink.RoomState do
  @moduledoc """
  Single entry point for all room state mutations.

  Handles DB persistence, memory cache, and broadcast internally,
  providing a unified interface for code block and stroke operations.
  """

  alias Ink.CanvasStore
  alias Ink.CodeBlocks
  alias Ink.CodeBlocks.CodeBlock
  alias Ink.Collaboration

  @pubsub InkWeb.PubSub

  @type room_slug :: String.t()
  @type code_block_map :: %{String.t() => any()}
  @type result :: {:ok, code_block_map()} | {:error, term()}

  @doc """
  Get the complete room state including code blocks and strokes.
  """
  @spec get_room_state(room_slug()) :: %{code_blocks: [code_block_map()], strokes: [map()]}
  def get_room_state(room_slug) do
    room = Collaboration.get_room_by_slug(room_slug)

    code_blocks =
      case room do
        nil -> []
        %{} -> CodeBlocks.get_code_blocks_by_room(room.id) |> Enum.map(&CodeBlocks.to_map/1)
      end

    strokes = CanvasStore.get_strokes(room_slug)

    %{code_blocks: code_blocks, strokes: strokes}
  end

  @doc """
  Create a new code block: persists to DB, updates memory cache, broadcasts to room.
  """
  @spec create_code_block(room_slug(), map()) :: result()
  def create_code_block(room_slug, attrs) do
    with {:ok, room} <- fetch_room(room_slug),
         attrs <- Map.put(attrs, "room_id", room.id),
         {:ok, code_block} <- CodeBlocks.create_code_block(attrs) do
      broadcast_insert(room_slug, code_block)
    else
      {:error, :room_not_found} -> {:error, :room_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Update code block content: persists to DB, updates memory cache, broadcasts to room.
  """
  @spec update_code_block(room_slug(), pos_integer(), map()) :: result()
  def update_code_block(room_slug, code_block_id, attrs) do
    with {:ok, code_block} <- fetch_code_block(code_block_id),
         {:ok, updated} <- CodeBlocks.update_content(code_block, Map.get(attrs, "code")) do
      broadcast_update(room_slug, "code_block_updated", updated)
    end
  end

  @doc """
  Move code block to new position: persists to DB, updates memory cache, broadcasts to room.
  """
  @spec move_code_block(room_slug(), pos_integer(), number(), number()) :: result()
  def move_code_block(room_slug, code_block_id, x, y) do
    with {:ok, code_block} <- fetch_code_block(code_block_id),
         {:ok, updated} <- CodeBlocks.update_position(code_block, x, y) do
      broadcast_update(room_slug, "code_block_moved", updated)
    end
  end

  @doc """
  Resize code block: persists to DB, updates memory cache, broadcasts to room.
  """
  @spec resize_code_block(room_slug(), pos_integer(), number()) :: result()
  def resize_code_block(room_slug, code_block_id, width) do
    with {:ok, code_block} <- fetch_code_block(code_block_id),
         {:ok, updated} <- CodeBlocks.update_width(code_block, width) do
      broadcast_update(room_slug, "code_block_resized", updated)
    end
  end

  @doc """
  Delete code block: removes from DB, updates memory cache, broadcasts to room.
  """
  @spec delete_code_block(room_slug(), pos_integer()) ::
          {:ok, %{id: pos_integer()}} | {:error, term()}
  def delete_code_block(room_slug, code_block_id) do
    with {:ok, code_block} <- fetch_code_block(code_block_id),
         {:ok, _} <- CodeBlocks.delete_code_block(code_block) do
      CanvasStore.remove_code_block(room_slug, code_block_id)
      broadcast(room_slug, "code_block_deleted", %{id: code_block_id})
      {:ok, %{id: code_block_id}}
    end
  end

  @doc """
  Change code block language: persists to DB, updates memory cache, broadcasts to room.
  """
  @spec change_language(room_slug(), pos_integer(), String.t()) :: result()
  def change_language(room_slug, code_block_id, language) do
    with {:ok, code_block} <- fetch_code_block(code_block_id),
         {:ok, updated} <- CodeBlocks.update_language(code_block, language) do
      broadcast_update(room_slug, "code_block_language_changed", updated)
    end
  end

  @doc """
  Update code block output: persists to DB, updates memory cache, broadcasts to room.
  """
  @spec update_output(room_slug(), pos_integer(), String.t() | nil) :: result()
  def update_output(room_slug, code_block_id, output) do
    with {:ok, code_block} <- fetch_code_block(code_block_id),
         {:ok, updated} <- CodeBlocks.update_output(code_block, output) do
      broadcast_update(room_slug, "code_block_output_updated", updated)
    end
  end

  @doc """
  Start a new stroke with optional color. Memory-only operation.
  """
  @spec start_stroke(room_slug(), String.t() | nil) :: :ok
  def start_stroke(room_slug, color \\ nil) do
    CanvasStore.start_stroke(room_slug, color)
    :ok
  end

  @doc """
  Add a point to the current stroke. Memory-only operation.
  """
  @spec add_point(room_slug(), number(), number()) :: :ok
  def add_point(room_slug, x, y) do
    CanvasStore.add_point(room_slug, x, y)
    :ok
  end

  @doc """
  Undo the most recent stroke time window. Memory-only operation.
  Returns the updated strokes list on success.
  """
  @spec undo_stroke(room_slug()) :: {:ok, %{strokes: [map()]}}
  def undo_stroke(room_slug) do
    {:ok, strokes} = CanvasStore.undo(room_slug)
    broadcast(room_slug, "strokes_replaced", %{strokes: strokes})
    {:ok, %{strokes: strokes}}
  end

  defp fetch_room(room_slug) do
    case Collaboration.get_room_by_slug(room_slug) do
      nil -> {:error, :room_not_found}
      room -> {:ok, room}
    end
  end

  defp fetch_code_block(code_block_id) do
    case CodeBlocks.get_code_block(code_block_id) do
      nil -> {:error, :not_found}
      code_block -> {:ok, code_block}
    end
  end

  defp broadcast_insert(room_slug, %CodeBlock{} = code_block) do
    map = CodeBlocks.to_map(code_block)
    CanvasStore.put_code_block(room_slug, map)
    broadcast(room_slug, "code_block_inserted", map)
    {:ok, map}
  end

  defp broadcast_update(room_slug, event, %CodeBlock{} = code_block) do
    map = CodeBlocks.to_map(code_block)
    CanvasStore.update_code_block_in_memory(room_slug, map)
    broadcast(room_slug, event, map)
    {:ok, map}
  end

  defp broadcast(room_slug, event, payload) do
    Phoenix.PubSub.broadcast(@pubsub, topic(room_slug), {event, payload})
  end

  defp topic(room_slug), do: "room:#{room_slug}"
end
