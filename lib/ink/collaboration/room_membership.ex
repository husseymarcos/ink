defmodule Ink.Collaboration.RoomMembership do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ink.Accounts.User
  alias Ink.Collaboration.Room

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "room_memberships" do
    belongs_to :room, Room
    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:room_id, :user_id])
    |> validate_required([:room_id, :user_id])
    |> unique_constraint([:room_id, :user_id])
  end
end
