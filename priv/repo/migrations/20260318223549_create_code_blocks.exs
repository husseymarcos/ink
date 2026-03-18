defmodule Ink.Repo.Migrations.CreateCodeBlocks do
  use Ecto.Migration

  def change do
    create table(:code_blocks, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :room_id, references(:rooms, type: :uuid, on_delete: :delete_all), null: false
      add :language, :string, null: false, default: "javascript"
      add :code, :text, null: false, default: ""
      add :output, :text
      add :name, :string
      add :x, :float, null: false, default: 0.0
      add :y, :float, null: false, default: 0.0
      add :width, :integer, null: false, default: 400
      add :z_index, :integer, null: false, default: 0

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end

    create index(:code_blocks, [:room_id])
  end
end
