defmodule Ink.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ink.Accounts.Password
  alias Ink.Collaboration.Room
  alias Ink.Collaboration.RoomMembership

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :hashed_password, :string
    field :password, :string, virtual: true, redact: true

    has_many :owned_rooms, Room, foreign_key: :owner_id
    many_to_many :rooms, Room, join_through: RoomMembership

    timestamps(type: :utc_datetime_usec)
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> update_change(:email, &(String.trim(&1) |> String.downcase()))
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:password, min: 8, max: 72)
    |> unique_constraint(:email, name: :users_lower_email_index)
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true} = changeset) do
    password = get_change(changeset, :password)
    put_change(changeset, :hashed_password, Password.hash_password(password))
  end

  defp put_password_hash(changeset), do: changeset
end
