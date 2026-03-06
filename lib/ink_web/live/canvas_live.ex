defmodule InkWeb.CanvasLive do
  use InkWeb, :live_view

  alias Ink.Collaboration

  @palette [
    "#1e293b",
    "#dc2626",
    "#ea580c",
    "#ca8a04",
    "#16a34a",
    "#0891b2",
    "#3b82f6",
    "#7c3aed",
    "#db2777",
    "#ffffff"
  ]

  @impl true
  def mount(params, _session, socket) do
    socket = assign(socket, :page_title, "Canvas")
    socket = assign(socket, :current_color, Ink.Canvas.default_color())
    socket = assign(socket, :palette, @palette)
    socket = assign(socket, :shared_users, [])
    socket = assign(socket, :share_form, to_form(%{"email" => ""}, as: :share))

    case params do
      %{"room_id" => room_id} ->
        mount_room(socket, room_id)

      _ ->
        {:ok, redirect(socket, to: "/room/#{random_slug()}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={%{}} current_user={@current_user}>
      <div class="fixed inset-0 z-50 flex flex-col bg-base-100" data-canvas-container>
        <div class="pointer-events-none absolute left-0 top-0 z-20 flex items-start gap-3 p-3">
          <span class="rounded bg-base-100/90 px-2 py-1 text-xs font-mono text-base-content shadow-sm backdrop-blur-sm sm:text-sm">
            {@room_id}
          </span>

          <div class="pointer-events-auto rounded-xl bg-base-100/95 p-2 shadow-md backdrop-blur-sm">
            <.form
              for={@share_form}
              id="share-room-form"
              phx-submit="share_room"
              class="flex items-end gap-2"
            >
              <div class="min-w-52">
                <.input
                  field={@share_form[:email]}
                  type="email"
                  label="Compartir por email"
                  placeholder="persona@email.com"
                  required
                />
              </div>
              <button type="submit" class="btn btn-primary btn-sm">
                Compartir
              </button>
            </.form>

            <p class="mt-2 text-xs font-medium text-base-content/70">Con acceso:</p>
            <div class="mt-1 flex max-w-xs flex-wrap gap-1.5">
              <span class="rounded-full bg-primary/10 px-2 py-1 text-xs text-primary">
                {@current_user.email} (owner)
              </span>
              <span
                :for={user <- @shared_users}
                class="rounded-full bg-base-200 px-2 py-1 text-xs text-base-content"
              >
                {user.email}
              </span>
            </div>
          </div>
        </div>
        <div class="pointer-events-auto absolute right-0 top-0 z-20 p-3">
          <div class="mb-2 flex justify-end">
            <.link
              href={~p"/logout"}
              method="delete"
              class="rounded bg-base-100/90 px-3 py-1.5 text-xs font-medium text-base-content shadow-sm backdrop-blur-sm transition hover:bg-base-200"
            >
              Salir
            </.link>
          </div>
          <button
            type="button"
            data-canvas-undo
            class="inline-flex items-center gap-2 rounded-lg bg-base-100/90 px-3 py-2 text-sm font-medium text-base-content shadow-sm backdrop-blur-sm transition hover:bg-base-200 focus:ring-2 focus:ring-primary disabled:pointer-events-none disabled:opacity-50"
            title="Deshacer (⌘Z)"
          >
            <.icon name="hero-arrow-uturn-left" class="h-4 w-4" /> Deshacer
          </button>
        </div>
        <div class="pointer-events-auto absolute inset-x-0 bottom-0 z-20 flex justify-center p-3">
          <div
            class="flex flex-wrap justify-center gap-1.5 rounded-xl bg-base-100/95 p-2 shadow-lg shadow-black/10 backdrop-blur-sm"
            role="group"
            aria-label="Paleta de colores"
          >
            <%= for color <- @palette do %>
              <button
                type="button"
                phx-click="select_color"
                phx-value-color={color}
                class={[
                  "h-8 w-8 shrink-0 rounded-lg border-2 transition-all focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 focus:ring-offset-base-100",
                  if(@current_color == color,
                    do: "scale-110 border-base-content shadow-md",
                    else: "border-transparent hover:scale-105 hover:shadow"
                  )
                ]}
                style={"background-color: #{color}; box-shadow: #{if(color == "#ffffff", do: "inset 0 0 0 1px rgba(0,0,0,0.15)", else: "none")}"}
                title={color}
              >
              </button>
            <% end %>
          </div>
        </div>
        <div class="absolute inset-0 bg-base-100">
          <canvas
            id="ink-canvas"
            phx-hook="CanvasDraw"
            phx-update="ignore"
            data-room-id={@room_id}
            data-default-color={Ink.Canvas.default_color()}
            class="h-full w-full cursor-crosshair touch-none"
          >
          </canvas>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("select_color", %{"color" => color}, socket) do
    socket =
      socket
      |> assign(:current_color, color)
      |> push_event("set_color", %{color: color})

    {:noreply, socket}
  end

  def handle_event("share_room", %{"share" => %{"email" => email}}, socket) do
    case Collaboration.share_room_with_email(
           socket.assigns.room,
           socket.assigns.current_user,
           email
         ) do
      {:ok, _membership} ->
        {:noreply,
         socket
         |> put_flash(:info, "Room compartido con #{email}.")
         |> assign(:share_form, to_form(%{"email" => ""}, as: :share))
         |> assign(:shared_users, Collaboration.list_room_users(socket.assigns.room))}

      {:error, :owner_cannot_be_shared} ->
        {:noreply, put_flash(socket, :error, "El owner ya tiene acceso al room.")}

      {:error, :not_owner} ->
        {:noreply, put_flash(socket, :error, "Solo el owner puede compartir este room.")}

      {:error, :user_not_found} ->
        {:noreply, put_flash(socket, :error, "No existe un usuario con ese email.")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :info, "Ese usuario ya tenía acceso.")}

      _ ->
        {:noreply, put_flash(socket, :error, "No se pudo compartir el room.")}
    end
  end

  defp random_slug do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
    |> String.downcase()
  end

  defp mount_room(socket, room_slug) do
    case Collaboration.get_or_create_accessible_room(room_slug, socket.assigns.current_user) do
      {:ok, room} ->
        {:ok,
         socket
         |> assign(:room, room)
         |> assign(:room_id, room.slug)
         |> assign(:shared_users, Collaboration.list_room_users(room))}

      {:error, :forbidden} ->
        {:ok,
         socket
         |> put_flash(:error, "No tienes acceso a ese room.")
         |> redirect(to: "/room/#{random_slug()}")}

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "No se pudo abrir el room.")
         |> redirect(to: "/room/#{random_slug()}")}
    end
  end
end
