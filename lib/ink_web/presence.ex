defmodule InkWeb.Presence do
  @moduledoc """
  Tracks user presence on canvas rooms and other real-time topics.

  We use Phoenix.Presence on top of Ink.PubSub so that any part of the app
  can query how many users are connected to a given topic.
  """

  use Phoenix.Presence,
    otp_app: :ink,
    pubsub_server: Ink.PubSub
end

