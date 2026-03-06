defmodule Ink.Collaboration.Room do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ink.Accounts.User
  alias Ink.Collaboration.RoomMembership

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field :name, :string
    field :slug, :string

    belongs_to :owner, User
    many_to_many :users, User, join_through: RoomMembership

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :slug, :owner_id])
    |> validate_required([:name, :slug, :owner_id])
    |> unique_constraint(:slug)
  end
end
