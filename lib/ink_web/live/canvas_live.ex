defmodule InkWeb.CanvasLive do
  use InkWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Canvas")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex flex-col items-center gap-4 py-8">
        <h1 class="text-2xl font-semibold text-base-content">Real-time canvas</h1>
        <p class="text-sm text-base-content/70">Click and drag to draw. Others will see it live.</p>
        <div class="border-2 border-base-300 rounded-lg overflow-hidden bg-white shadow-lg">
          <canvas
            id="ink-canvas"
            phx-hook="CanvasDraw"
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
end
