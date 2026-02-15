defmodule InkWeb.CanvasLive do
  use InkWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    socket = assign(socket, :page_title, "Canvas")

    case params do
      %{"room_id" => room_id} ->
        {:ok, assign(socket, :room_id, room_id)}

      _ ->
        {:ok, redirect(socket, to: "/room/#{random_slug()}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex flex-col items-center gap-4 py-8">
        <h1 class="text-2xl font-semibold text-base-content">Real-time canvas</h1>
        <p class="text-sm text-base-content/70">
          Click and drag to draw. Share the URL so others see the same room.
        </p>
        <div class="border-2 border-base-300 rounded-lg overflow-hidden bg-white shadow-lg">
          <canvas
            id="ink-canvas"
            phx-hook="CanvasDraw"
            phx-update="ignore"
            data-room-id={@room_id}
            width="800"
            height="500"
            class="cursor-crosshair block touch-none"
          >
          </canvas>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp random_slug do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
    |> String.downcase()
  end
end
