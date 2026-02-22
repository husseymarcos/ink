defmodule Ink.Resources.Room do
  @moduledoc """
  A canvas room. Persisted in Postgres via Ash.
  """
  use Ash.Resource,
    domain: Ink.Resources,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "rooms"
    repo Ink.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:name]
    end

    update :update do
      primary? true
      accept [:name]
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end
end
