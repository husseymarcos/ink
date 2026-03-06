defmodule Ink.CollaborationTest do
  use Ink.DataCase, async: true

  alias Ink.Accounts
  alias Ink.Collaboration

  describe "get_or_create_accessible_room/2" do
    test "creates a new room and grants access to owner" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "owner@example.com",
          "password" => "supersecret1"
        })

      assert {:ok, room} = Collaboration.get_or_create_accessible_room("new-room", owner)
      assert room.slug == "new-room"
      assert Collaboration.user_has_access?(room, owner)
    end

    test "returns forbidden for users without access to existing room" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "owner@example.com",
          "password" => "supersecret1"
        })

      {:ok, outsider} =
        Accounts.register_user(%{
          "email" => "outsider@example.com",
          "password" => "supersecret1"
        })

      {:ok, _room} = Collaboration.create_room("private-room", owner)

      assert {:error, :forbidden} =
               Collaboration.get_or_create_accessible_room("private-room", outsider)
    end
  end

  test "owner can share room with another user by email" do
    {:ok, owner} =
      Accounts.register_user(%{
        "email" => "owner@example.com",
        "password" => "supersecret1"
      })

    {:ok, invited} =
      Accounts.register_user(%{
        "email" => "invited@example.com",
        "password" => "supersecret1"
      })

    {:ok, room} = Collaboration.create_room("shared-room", owner)

    assert {:ok, _membership} =
             Collaboration.share_room_with_email(room, owner, invited.email)

    assert Collaboration.user_has_access?(room, invited)
  end

  describe "share_room_with_email/3" do
    test "returns not_owner when actor is not owner" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "owner@example.com",
          "password" => "supersecret1"
        })

      {:ok, actor} =
        Accounts.register_user(%{
          "email" => "actor@example.com",
          "password" => "supersecret1"
        })

      {:ok, invited} =
        Accounts.register_user(%{
          "email" => "invited@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("private-room", owner)

      assert {:error, :not_owner} =
               Collaboration.share_room_with_email(room, actor, invited.email)
    end

    test "returns user_not_found when email is unknown" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "owner@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("private-room", owner)

      assert {:error, :user_not_found} =
               Collaboration.share_room_with_email(room, owner, "missing@example.com")
    end

    test "returns owner_cannot_be_shared when sharing with owner email" do
      {:ok, owner} =
        Accounts.register_user(%{
          "email" => "owner@example.com",
          "password" => "supersecret1"
        })

      {:ok, room} = Collaboration.create_room("private-room", owner)

      assert {:error, :owner_cannot_be_shared} =
               Collaboration.share_room_with_email(room, owner, owner.email)
    end
  end

  test "list_room_users excludes owner and sorts by email" do
    {:ok, owner} =
      Accounts.register_user(%{
        "email" => "owner@example.com",
        "password" => "supersecret1"
      })

    {:ok, invited_b} =
      Accounts.register_user(%{
        "email" => "b@example.com",
        "password" => "supersecret1"
      })

    {:ok, invited_a} =
      Accounts.register_user(%{
        "email" => "a@example.com",
        "password" => "supersecret1"
      })

    {:ok, room} = Collaboration.create_room("shared-room", owner)

    assert {:ok, _} = Collaboration.share_room_with_email(room, owner, invited_b.email)
    assert {:ok, _} = Collaboration.share_room_with_email(room, owner, invited_a.email)

    users = Collaboration.list_room_users(room)

    assert Enum.map(users, & &1.email) == ["a@example.com", "b@example.com"]
  end
end
