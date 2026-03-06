defmodule Ink.Accounts do
  @moduledoc "Accounts context for user registration and authentication."

  import Ecto.Query, warn: false
  alias Ink.Accounts.{Password, User}
  alias Ink.Repo

  def get_user(id) when is_binary(id), do: Repo.get(User, id)
  def get_user(_), do: nil

  def get_user_by_email(email) when is_binary(email) do
    normalized_email = email |> String.trim() |> String.downcase()

    from(u in User, where: fragment("lower(?)", u.email) == ^normalized_email)
    |> Repo.one()
  end

  def get_user_by_email(_), do: nil

  def register_user(attrs) when is_map(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def authenticate_user(email, password) when is_binary(email) and is_binary(password) do
    case get_user_by_email(email) do
      %User{} = user ->
        if Password.valid_password?(user.hashed_password, password), do: {:ok, user}, else: :error

      nil ->
        _ = Password.no_user_verify(password)
        :error
    end
  end

  def authenticate_user(_, _), do: :error
end
