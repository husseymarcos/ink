defmodule Ink.CollaborationTest do
  use Ink.DataCase, async: true

  alias Ink.Accounts
  alias Ink.Collaboration

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
end
