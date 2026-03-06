defmodule Ink.AccountsTest do
  use Ink.DataCase, async: true

  alias Ink.Accounts

  describe "register_user/1" do
    test "normalizes email and stores hashed password" do
      assert {:ok, user} =
               Accounts.register_user(%{
                 "email" => "  MIXED@Example.COM  ",
                 "password" => "supersecret1"
               })

      assert user.email == "mixed@example.com"
      assert is_binary(user.hashed_password)
      refute user.hashed_password == "supersecret1"
    end

    test "rejects duplicate email regardless of case" do
      assert {:ok, _user} =
               Accounts.register_user(%{
                 "email" => "already@example.com",
                 "password" => "supersecret1"
               })

      assert {:error, changeset} =
               Accounts.register_user(%{
                 "email" => "ALREADY@example.com",
                 "password" => "supersecret1"
               })

      assert %{email: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "get_user_by_email/1" do
    test "finds user with case-insensitive and trimmed email" do
      assert {:ok, user} =
               Accounts.register_user(%{
                 "email" => "person@example.com",
                 "password" => "supersecret1"
               })

      assert found = Accounts.get_user_by_email("  PERSON@example.com ")
      assert found.id == user.id
    end
  end

  describe "authenticate_user/2" do
    test "returns user for valid credentials" do
      assert {:ok, user} =
               Accounts.register_user(%{
                 "email" => "person@example.com",
                 "password" => "supersecret1"
               })

      assert {:ok, authenticated} =
               Accounts.authenticate_user("person@example.com", "supersecret1")

      assert authenticated.id == user.id
    end

    test "returns error for invalid password" do
      assert {:ok, _user} =
               Accounts.register_user(%{
                 "email" => "person@example.com",
                 "password" => "supersecret1"
               })

      assert :error = Accounts.authenticate_user("person@example.com", "wrong-pass")
    end

    test "returns error for unknown user" do
      assert :error = Accounts.authenticate_user("missing@example.com", "supersecret1")
    end
  end
end
