defmodule Ink.Repo.Migrations.AddUsersAndRoomMemberships do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :email, :text, null: false
      add :hashed_password, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:users, ["lower(email)"], name: :users_lower_email_index)

    alter table(:rooms) do
      add :slug, :text
      add :owner_id, references(:users, type: :uuid, on_delete: :nilify_all)
    end

    execute(
      "UPDATE rooms SET slug = substr(md5(gen_random_uuid()::text), 1, 16) WHERE slug IS NULL"
    )

    execute("ALTER TABLE rooms ALTER COLUMN slug SET NOT NULL")

    create unique_index(:rooms, [:slug])
    create index(:rooms, [:owner_id])

    create table(:room_memberships, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :room_id, references(:rooms, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:room_memberships, [:room_id, :user_id])
    create index(:room_memberships, [:user_id])
  end
end
