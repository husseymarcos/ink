defmodule Ink.Accounts.Password do
  @moduledoc false

  @algorithm :sha256
  @iterations 120_000
  @key_length 32
  @salt_length 16
  @dummy_salt "ink-dummy-salt"

  def hash_password(password) when is_binary(password) do
    salt = :crypto.strong_rand_bytes(@salt_length)
    derived = :crypto.pbkdf2_hmac(@algorithm, password, salt, @iterations, @key_length)

    "pbkdf2_sha256$#{@iterations}$#{encode64(salt)}$#{encode64(derived)}"
  end

  def valid_password?(stored_hash, password)
      when is_binary(stored_hash) and is_binary(password) do
    with ["pbkdf2_sha256", iteration_text, salt_text, expected_text] <-
           String.split(stored_hash, "$"),
         {iterations, ""} <- Integer.parse(iteration_text),
         {:ok, salt} <- decode64(salt_text),
         {:ok, expected} <- decode64(expected_text) do
      actual = :crypto.pbkdf2_hmac(@algorithm, password, salt, iterations, byte_size(expected))

      byte_size(actual) == byte_size(expected) and Plug.Crypto.secure_compare(actual, expected)
    else
      _ -> false
    end
  end

  def valid_password?(_, _), do: false

  def no_user_verify(password) when is_binary(password) do
    _ = :crypto.pbkdf2_hmac(@algorithm, password, @dummy_salt, @iterations, @key_length)
    false
  end

  defp encode64(binary), do: Base.url_encode64(binary, padding: false)

  defp decode64(text), do: Base.url_decode64(text, padding: false)
end
