defmodule Ink.CodeBlocksTest do
  use Ink.DataCase, async: true

  alias Ink.Accounts
  alias Ink.Collaboration
  alias Ink.CodeBlocks
  alias Ink.CodeBlocks.CodeBlock

  describe "CodeBlock schema" do
    test "templates returns correct templates for each language" do
      templates = CodeBlock.templates()
      assert templates["javascript"] == "console.log(\"Hello, World!\");"
      assert templates["python"] == "print(\"Hello, World!\")"
    end

    test "languages returns valid language options" do
      languages = CodeBlock.languages()
      assert "javascript" in languages
      assert "python" in languages
    end
  end

  describe "create_code_block/1" do
    test "creates a code block with defaults" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("test-room", owner)

      {:ok, code_block} =
        CodeBlocks.create_code_block(%{
          "room_id" => room.id
        })

      assert code_block.room_id == room.id
      assert code_block.language == "javascript"
      assert code_block.code == "console.log(\"Hello, World!\");"
      assert code_block.width == 400
    end

    test "creates a code block with custom language and code" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("test-room", owner)

      {:ok, code_block} =
        CodeBlocks.create_code_block(%{
          "room_id" => room.id,
          "language" => "python",
          "code" => "x = 1"
        })

      assert code_block.language == "python"
      assert code_block.code == "x = 1"
    end

    test "creates a code block at specified position" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("test-room", owner)

      {:ok, code_block} =
        CodeBlocks.create_code_block(%{
          "room_id" => room.id,
          "x" => 100.5,
          "y" => 200.5,
          "width" => 500
        })

      assert code_block.x == 100.5
      assert code_block.y == 200.5
      assert code_block.width == 500
    end
  end

  describe "get_code_block/1" do
    test "returns code block by id" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("test-room", owner)

      {:ok, created} =
        CodeBlocks.create_code_block(%{
          "room_id" => room.id
        })

      assert %CodeBlock{} = CodeBlocks.get_code_block(created.id)
    end

    test "returns nil for non-existent id" do
      assert CodeBlocks.get_code_block(Ecto.UUID.generate()) == nil
    end
  end

  describe "get_code_blocks_by_room/1" do
    test "returns code blocks for a room" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("test-room", owner)

      {:ok, _cb1} =
        CodeBlocks.create_code_block(%{
          "room_id" => room.id,
          "x" => 0,
          "y" => 0
        })

      {:ok, _cb2} =
        CodeBlocks.create_code_block(%{
          "room_id" => room.id,
          "x" => 0,
          "y" => 0
        })

      blocks = CodeBlocks.get_code_blocks_by_room(room.id)
      assert length(blocks) == 2
    end

    test "returns empty list for room with no code blocks" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("test-room", owner)

      blocks = CodeBlocks.get_code_blocks_by_room(room.id)
      assert blocks == []
    end
  end

  describe "update_position/3" do
    test "updates code block position" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("test-room", owner)

      {:ok, code_block} =
        CodeBlocks.create_code_block(%{
          "room_id" => room.id
        })

      {:ok, updated} = CodeBlocks.update_position(code_block, 150.0, 250.0)

      assert updated.x == 150.0
      assert updated.y == 250.0
    end
  end

  describe "update_content/2" do
    test "updates code block content" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("test-room", owner)

      {:ok, code_block} =
        CodeBlocks.create_code_block(%{
          "room_id" => room.id
        })

      {:ok, updated} = CodeBlocks.update_content(code_block, "new code")

      assert updated.code == "new code"
    end
  end

  describe "update_language/2" do
    test "changes language and resets code to template" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("test-room", owner)

      {:ok, code_block} =
        CodeBlocks.create_code_block(%{
          "room_id" => room.id,
          "code" => "custom code"
        })

      {:ok, updated} = CodeBlocks.update_language(code_block, "python")

      assert updated.language == "python"
      assert updated.code == "print(\"Hello, World!\")"
      assert updated.output == nil
    end
  end

  describe "update_output/2" do
    test "updates code block output" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("test-room", owner)

      {:ok, code_block} =
        CodeBlocks.create_code_block(%{
          "room_id" => room.id
        })

      {:ok, updated} = CodeBlocks.update_output(code_block, "Hello, World!")

      assert updated.output == "Hello, World!"
    end
  end

  describe "update_width/2" do
    test "updates code block width" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("test-room", owner)

      {:ok, code_block} =
        CodeBlocks.create_code_block(%{
          "room_id" => room.id
        })

      {:ok, updated} = CodeBlocks.update_width(code_block, 600)

      assert updated.width == 600
    end
  end

  describe "delete_code_block/1" do
    test "deletes code block" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("test-room", owner)

      {:ok, code_block} =
        CodeBlocks.create_code_block(%{
          "room_id" => room.id
        })

      assert {:ok, _} = CodeBlocks.delete_code_block(code_block)
      assert CodeBlocks.get_code_block(code_block.id) == nil
    end
  end

  describe "to_map/1" do
    test "converts code block to map" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "test@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("test-room", owner)

      {:ok, code_block} =
        CodeBlocks.create_code_block(%{
          "room_id" => room.id,
          "language" => "python"
        })

      map = CodeBlocks.to_map(code_block)

      assert map["id"] == code_block.id
      assert map["room_id"] == room.id
      assert map["language"] == "python"
      assert map["code"] == "print(\"Hello, World!\")"
    end
  end
end
