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
      <div class="fixed inset-0 z-50 flex flex-col bg-base-100" data-canvas-container>
        <div class="pointer-events-none absolute left-0 top-0 z-20 flex items-center gap-3 p-3">
          <span class="rounded bg-base-100/90 px-2 py-1 text-sm font-mono text-base-content shadow-sm backdrop-blur-sm">
            {@room_id}
          </span>
        </div>
        <div class="pointer-events-auto absolute right-0 top-0 z-20 p-3">
          <button
            type="button"
            data-canvas-undo
            class="inline-flex items-center gap-2 rounded-lg bg-base-100/90 px-3 py-2 text-sm font-medium text-base-content shadow-sm backdrop-blur-sm transition hover:bg-base-200 focus:ring-2 focus:ring-primary disabled:pointer-events-none disabled:opacity-50"
            title="Deshacer (⌘Z)"
          >
            <.icon name="hero-arrow-uturn-left" class="h-4 w-4" /> Deshacer
          </button>
        </div>
        <div class="absolute inset-0 bg-base-100">
          <canvas
            id="ink-canvas"
            phx-hook="CanvasDraw"
            phx-update="ignore"
            data-room-id={@room_id}
            class="h-full w-full cursor-crosshair touch-none"
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
