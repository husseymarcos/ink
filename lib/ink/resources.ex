defmodule Ink.Resources do
  @moduledoc """
  Ash domain for Ink's persisted resources (rooms, etc.).
  """
  use Ash.Domain

  resources do
    resource Ink.Resources.Room
  end
end
