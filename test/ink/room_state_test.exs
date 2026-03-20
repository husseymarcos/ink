defmodule Ink.RoomStateTest do
  use Ink.DataCase, async: false

  alias Ink.Accounts
  alias Ink.CanvasStore
  alias Ink.Collaboration
  alias Ink.RoomState

  setup do
    Phoenix.PubSub.Supervisor.start_link(name: InkWeb.PubSub)
    :ok
  end

  describe "get_room_state/1" do
    test "returns empty state for non-existent room" do
      state = RoomState.get_room_state("non-existent-room-#{:rand.uniform(10000)}")
      assert state.code_blocks == []
      assert state.strokes == []
    end

    test "returns code blocks and strokes for existing room" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      RoomState.create_code_block(room_slug, %{"x" => 0, "y" => 0, "width" => 400})
      RoomState.start_stroke(room_slug, "#000000")
      RoomState.add_point(room_slug, 10.0, 20.0)

      state = RoomState.get_room_state(room_slug)

      assert length(state.code_blocks) == 1
      assert length(state.strokes) == 1
    end
  end

  describe "create_code_block/2" do
    test "persists to DB and cache" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      attrs = %{"x" => 100, "y" => 200, "width" => 500, "language" => "javascript"}
      assert {:ok, code_block_map} = RoomState.create_code_block(room_slug, attrs)

      assert code_block_map["x"] == 100
      assert code_block_map["y"] == 200
      assert code_block_map["width"] == 500
      assert code_block_map["language"] == "javascript"

      cached = CanvasStore.get_code_blocks(room_slug)
      assert Map.has_key?(cached, code_block_map["id"])
    end

    test "returns error for non-existent room" do
      result = RoomState.create_code_block("non-existent-room-#{:rand.uniform(10000)}", %{})
      assert result == {:error, :room_not_found}
    end
  end

  describe "update_code_block/3" do
    test "updates code content and syncs to cache" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      {:ok, created} = RoomState.create_code_block(room_slug, %{"x" => 0, "y" => 0})

      assert {:ok, updated} =
               RoomState.update_code_block(room_slug, created["id"], %{"code" => "new code"})

      assert updated["code"] == "new code"

      cached = CanvasStore.get_code_blocks(room_slug)
      assert cached[created["id"]]["code"] == "new code"
    end

    test "returns error for non-existent code block" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      fake_id = Ecto.UUID.generate()

      assert {:error, :not_found} =
               RoomState.update_code_block(room_slug, fake_id, %{"code" => "test"})
    end
  end

  describe "move_code_block/4" do
    test "updates position and syncs to cache" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      {:ok, created} = RoomState.create_code_block(room_slug, %{"x" => 0, "y" => 0})

      assert {:ok, updated} = RoomState.move_code_block(room_slug, created["id"], 150.0, 250.0)
      assert updated["x"] == 150.0
      assert updated["y"] == 250.0

      cached = CanvasStore.get_code_blocks(room_slug)
      assert cached[created["id"]]["x"] == 150.0
      assert cached[created["id"]]["y"] == 250.0
    end

    test "returns error for non-existent block" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      fake_id = Ecto.UUID.generate()
      assert {:error, :not_found} = RoomState.move_code_block(room_slug, fake_id, 0, 0)
    end
  end

  describe "resize_code_block/3" do
    test "updates width and syncs to cache" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      {:ok, created} =
        RoomState.create_code_block(room_slug, %{"x" => 0, "y" => 0, "width" => 400})

      assert {:ok, updated} = RoomState.resize_code_block(room_slug, created["id"], 600)
      assert updated["width"] == 600

      cached = CanvasStore.get_code_blocks(room_slug)
      assert cached[created["id"]]["width"] == 600
    end
  end

  describe "delete_code_block/2" do
    test "removes from DB and cache" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      {:ok, created} = RoomState.create_code_block(room_slug, %{"x" => 0, "y" => 0})

      assert {:ok, %{id: id}} = RoomState.delete_code_block(room_slug, created["id"])
      assert id == created["id"]

      cached = CanvasStore.get_code_blocks(room_slug)
      refute Map.has_key?(cached, created["id"])
    end

    test "returns error for non-existent block" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      fake_id = Ecto.UUID.generate()
      assert {:error, :not_found} = RoomState.delete_code_block(room_slug, fake_id)
    end
  end

  describe "change_language/3" do
    test "updates language and syncs to cache" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      {:ok, created} = RoomState.create_code_block(room_slug, %{"language" => "javascript"})

      assert {:ok, updated} = RoomState.change_language(room_slug, created["id"], "python")
      assert updated["language"] == "python"
      assert updated["code"] == "print(\"Hello, World!\")"

      cached = CanvasStore.get_code_blocks(room_slug)
      assert cached[created["id"]]["language"] == "python"
    end
  end

  describe "update_output/3" do
    test "updates output and syncs to cache" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      {:ok, created} = RoomState.create_code_block(room_slug, %{})

      assert {:ok, updated} = RoomState.update_output(room_slug, created["id"], "Hello, World!")
      assert updated["output"] == "Hello, World!"

      cached = CanvasStore.get_code_blocks(room_slug)
      assert cached[created["id"]]["output"] == "Hello, World!"
    end
  end

  describe "start_stroke/2" do
    test "starts a stroke in memory" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      assert :ok = RoomState.start_stroke(room_slug, "#ff0000")

      strokes = CanvasStore.get_strokes(room_slug)
      assert length(strokes) == 1
      assert hd(strokes).color == "#ff0000"
    end

    test "uses default color when none provided" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      assert :ok = RoomState.start_stroke(room_slug)

      strokes = CanvasStore.get_strokes(room_slug)
      assert length(strokes) == 1
      assert hd(strokes).color == "#3b82f6"
    end
  end

  describe "add_point/3" do
    test "adds point to current stroke" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      RoomState.start_stroke(room_slug)
      assert :ok = RoomState.add_point(room_slug, 10.0, 20.0)

      strokes = CanvasStore.get_strokes(room_slug)
      assert length(strokes) == 1
      assert length(hd(strokes).points) == 1
      assert hd(strokes).points == [%{"x" => 10.0, "y" => 20.0}]
    end
  end

  describe "undo_stroke/1" do
    test "removes recent stroke time window" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      RoomState.start_stroke(room_slug)
      RoomState.add_point(room_slug, 10.0, 20.0)
      RoomState.add_point(room_slug, 30.0, 40.0)

      assert {:ok, %{strokes: []}} = RoomState.undo_stroke(room_slug)
    end

    test "returns empty strokes for room with no strokes" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      room_slug = "test-room-#{:rand.uniform(10000)}"
      {:ok, _room} = Collaboration.create_room(room_slug, owner)

      assert {:ok, %{strokes: []}} = RoomState.undo_stroke(room_slug)
    end
  end
end
