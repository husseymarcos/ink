defmodule Ink.Collaboration do
  @moduledoc "Room ownership and sharing logic."

  import Ecto.Query, warn: false

  alias Ink.Accounts.User
  alias Ink.Collaboration.{Room, RoomMembership}
  alias Ink.Repo

  def get_room_by_slug(slug) when is_binary(slug), do: Repo.get_by(Room, slug: slug)
  def get_room_by_slug(_), do: nil

  def user_has_access?(%Room{owner_id: owner_id}, %User{id: user_id}) when owner_id == user_id,
    do: true

  def user_has_access?(%Room{id: room_id}, %User{id: user_id}) do
    from(m in RoomMembership, where: m.room_id == ^room_id and m.user_id == ^user_id)
    |> Repo.exists?()
  end

  def user_has_access?(_, _), do: false

  def get_or_create_accessible_room(slug, %User{} = user) when is_binary(slug) do
    case get_room_by_slug(slug) do
      nil ->
        create_room(slug, user)

      %Room{} = room ->
        if user_has_access?(room, user), do: {:ok, room}, else: {:error, :forbidden}
    end
  end

  def list_room_users(%Room{id: room_id, owner_id: owner_id}) do
    from(u in User,
      join: m in RoomMembership,
      on: m.user_id == u.id,
      where: m.room_id == ^room_id and m.user_id != ^owner_id,
      order_by: [asc: u.email]
    )
    |> Repo.all()
  end

  def create_room(slug, %User{} = owner) when is_binary(slug) do
    Repo.transaction(fn ->
      with {:ok, room} <-
             %Room{}
             |> Room.changeset(%{name: slug, slug: slug, owner_id: owner.id})
             |> Repo.insert(),
           {:ok, _membership} <-
             %RoomMembership{}
             |> RoomMembership.changeset(%{room_id: room.id, user_id: owner.id})
             |> Repo.insert() do
        room
      else
        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, room} -> {:ok, room}
      {:error, error} -> {:error, error}
    end
  end

  def list_owned_rooms(%User{id: user_id}) do
    from(r in Room,
      where: r.owner_id == ^user_id,
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
  end

  def list_shared_rooms(%User{id: user_id}) do
    from(r in Room,
      join: m in RoomMembership,
      on: m.room_id == r.id,
      where: m.user_id == ^user_id and r.owner_id != ^user_id,
      preload: [:owner],
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
  end

  def delete_room(%Room{} = room, %User{} = actor) do
    if room.owner_id != actor.id do
      {:error, :not_owner}
    else
      Repo.transaction(fn ->
        from(m in RoomMembership, where: m.room_id == ^room.id)
        |> Repo.delete_all()

        case Repo.delete(room) do
          {:ok, room} -> room
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
      |> case do
        {:ok, room} -> {:ok, room}
        {:error, error} -> {:error, error}
      end
    end
  end

  def list_owned_rooms(%User{id: user_id}) do
    from(r in Room,
      where: r.owner_id == ^user_id,
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
  end

  def list_shared_rooms(%User{id: user_id}) do
    from(r in Room,
      join: m in RoomMembership,
      on: m.room_id == r.id,
      where: m.user_id == ^user_id and r.owner_id != ^user_id,
      preload: [:owner],
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
  end

  def update_room_name(%Room{} = room, %User{} = actor, name) when is_binary(name) do
    if room.owner_id != actor.id do
      {:error, :not_owner}
    else
      name = name |> String.trim()
      name = if name == "", do: room.slug, else: name

      room
      |> Ecto.Changeset.change(%{name: name})
      |> Repo.update()
    end
  end

  def share_room_with_email(%Room{} = room, %User{} = actor, email) when is_binary(email) do
    if room.owner_id != actor.id do
      {:error, :not_owner}
    else
      normalized_email = email |> String.trim() |> String.downcase()

      case Repo.one(from(u in User, where: fragment("lower(?)", u.email) == ^normalized_email)) do
        nil ->
          {:error, :user_not_found}

        %User{id: user_id} when user_id == actor.id ->
          {:error, :owner_cannot_be_shared}

        %User{} = user ->
          %RoomMembership{}
          |> RoomMembership.changeset(%{room_id: room.id, user_id: user.id})
          |> Repo.insert(on_conflict: :nothing)
      end
    end
  end
end
