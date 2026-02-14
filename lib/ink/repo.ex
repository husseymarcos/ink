defmodule Ink.Repo do
  use Ecto.Repo,
    otp_app: :ink,
    adapter: Ecto.Adapters.Postgres
end
