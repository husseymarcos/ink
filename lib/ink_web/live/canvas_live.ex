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
    socket = Phoenix.Component.assign_new(socket, :current_user, fn -> nil end)
    socket = assign(socket, :page_title, "Canvas")
    socket = assign(socket, :current_color, Ink.Canvas.default_color())
    socket = assign(socket, :palette, @palette)
    socket = assign(socket, :shared_users, [])
    socket = assign(socket, :share_form, to_form(%{"email" => ""}, as: :share))
    socket = assign(socket, :share_modal_open?, false)
    socket = assign(socket, :room_name_modal_open?, false)
    socket = assign(socket, :room_name_form, to_form(%{"name" => ""}, as: :room_name))

    case socket.assigns.current_user do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Inicia sesion para continuar.")
         |> redirect(to: ~p"/login")}

      current_user ->
        case params do
          %{"room_id" => room_id} ->
            mount_room(socket, room_id, current_user)

          _ ->
            {:ok, redirect(socket, to: "/room/#{random_slug()}")}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={%{}} current_user={@current_user}>
      <div class="fixed inset-0 z-50 flex flex-col bg-base-100" data-canvas-container>
        <div class="pointer-events-none absolute inset-x-0 top-0 z-30 flex items-start justify-between p-3">
          <div class="pointer-events-auto">
            <.link
              href={~p"/logout"}
              method="delete"
              class="inline-flex items-center gap-2 rounded-lg bg-base-100/90 px-3 py-2 text-sm font-medium text-base-content shadow-sm backdrop-blur-sm transition hover:bg-base-200 focus:ring-2 focus:ring-primary"
            >
              <.icon name="hero-arrow-left-on-rectangle" class="h-4 w-4" /> Salir
            </.link>
          </div>

          <div class="pointer-events-auto relative flex items-start gap-2">
            <button
              type="button"
              phx-click="open_room_name"
              class="group flex flex-col items-end rounded-xl bg-base-100/90 px-3 py-2 text-right shadow-sm backdrop-blur-sm transition hover:bg-base-200 focus:ring-2 focus:ring-primary"
              title="Toca para renombrar"
            >
              <span class="flex items-center gap-2 text-sm font-semibold text-base-content">
                <span class="font-mono">{@room.name}</span>
              </span>
              <span class="text-xs font-medium text-base-content/60">
                Código: <span class="font-mono">{@room_id}</span>
              </span>
            </button>

            <button
              type="button"
              phx-click="open_share_modal"
              class="inline-flex items-center gap-2 rounded-lg bg-base-100/90 px-3 py-2 text-sm font-medium text-base-content shadow-sm backdrop-blur-sm transition hover:bg-base-200 focus:ring-2 focus:ring-primary"
              title="Compartir"
            >
              <.icon name="hero-share" class="h-4 w-4" /> Compartir
            </button>

            <button
              type="button"
              data-canvas-undo
              class="inline-flex items-center gap-2 rounded-lg bg-base-100/90 px-3 py-2 text-sm font-medium text-base-content shadow-sm backdrop-blur-sm transition hover:bg-base-200 focus:ring-2 focus:ring-primary disabled:pointer-events-none disabled:opacity-50"
              title="Deshacer (⌘Z)"
            >
              <.icon name="hero-arrow-uturn-left" class="h-4 w-4" /> Deshacer
            </button>

            <div
              :if={@room_name_modal_open?}
              class="absolute right-0 top-12 w-[22rem] rounded-2xl bg-base-100 p-4 shadow-xl ring-1 ring-base-300"
              role="dialog"
              aria-label="Renombrar room"
            >
              <div class="flex items-start justify-between gap-3">
                <div>
                  <p class="text-sm font-semibold text-base-content">Nombre del room</p>
                  <p class="text-xs text-base-content/60">
                    El código permanece igual: <span class="font-mono">{@room_id}</span>
                  </p>
                </div>
                <button
                  type="button"
                  phx-click="close_room_name"
                  class="rounded-lg p-1 text-base-content/60 transition hover:bg-base-200 hover:text-base-content"
                  aria-label="Cerrar"
                >
                  <.icon name="hero-x-mark" class="h-5 w-5" />
                </button>
              </div>

              <.form
                for={@room_name_form}
                id="room-name-form"
                phx-submit="save_room_name"
                class="mt-3"
              >
                <.input
                  field={@room_name_form[:name]}
                  type="text"
                  label="Nombre"
                  placeholder={@room_id}
                  required
                />

                <div class="mt-2 flex items-center justify-end gap-2">
                  <button
                    type="button"
                    phx-click="close_room_name"
                    class="btn btn-ghost btn-sm"
                  >
                    Cancelar
                  </button>
                  <button type="submit" class="btn btn-primary btn-sm">
                    Guardar
                  </button>
                </div>
              </.form>

              <p class="mt-2 text-xs text-base-content/60">
                Solo el owner puede cambiar el nombre del room.
              </p>
            </div>
          </div>
        </div>

        <div
          :if={@share_modal_open?}
          class="fixed inset-0 z-40"
          role="dialog"
          aria-label="Compartir room"
        >
          <button
            type="button"
            phx-click="close_share_modal"
            class="absolute inset-0 h-full w-full bg-black/40"
            aria-label="Cerrar"
          >
          </button>

          <div class="absolute inset-x-0 top-16 mx-auto w-[min(42rem,calc(100vw-1.5rem))] px-3 sm:top-20">
            <div class="relative overflow-hidden rounded-2xl bg-base-100 shadow-2xl ring-1 ring-base-300">
              <div class="flex items-start justify-between gap-4 border-b border-base-200 px-4 py-3">
                <div>
                  <p class="text-sm font-semibold text-base-content">Compartir</p>
                  <p class="text-xs text-base-content/60">
                    Código del room: <span class="font-mono">{@room_id}</span>
                  </p>
                </div>
                <button
                  type="button"
                  phx-click="close_share_modal"
                  class="rounded-lg p-1 text-base-content/60 transition hover:bg-base-200 hover:text-base-content"
                  aria-label="Cerrar"
                >
                  <.icon name="hero-x-mark" class="h-5 w-5" />
                </button>
              </div>

              <div class="px-4 py-4">
                <.form
                  for={@share_form}
                  id="share-room-form"
                  phx-submit="share_room"
                  class="flex flex-col gap-2 sm:flex-row sm:items-end"
                >
                  <div class="sm:min-w-80 sm:flex-1">
                    <.input
                      field={@share_form[:email]}
                      type="email"
                      label="Compartir por email"
                      placeholder="persona@email.com"
                      required
                    />
                  </div>
                  <button type="submit" class="btn btn-primary sm:mb-2">
                    Compartir
                  </button>
                </.form>

                <div class="mt-2">
                  <p class="text-xs font-medium text-base-content/70">Con acceso:</p>
                  <div class="mt-2 flex flex-wrap gap-1.5">
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
            </div>
          </div>
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

  def handle_event("open_share_modal", _params, socket) do
    {:noreply, assign(socket, :share_modal_open?, true)}
  end

  def handle_event("close_share_modal", _params, socket) do
    {:noreply, assign(socket, :share_modal_open?, false)}
  end

  def handle_event("open_room_name", _params, socket) do
    {:noreply, assign(socket, :room_name_modal_open?, true)}
  end

  def handle_event("close_room_name", _params, socket) do
    {:noreply,
     socket
     |> assign(:room_name_modal_open?, false)
     |> assign(:room_name_form, to_form(%{"name" => socket.assigns.room.name}, as: :room_name))}
  end

  def handle_event("save_room_name", %{"room_name" => %{"name" => name}}, socket) do
    case Collaboration.update_room_name(socket.assigns.room, socket.assigns.current_user, name) do
      {:ok, room} ->
        {:noreply,
         socket
         |> assign(:room, room)
         |> assign(:room_name_modal_open?, false)
         |> assign(:room_name_form, to_form(%{"name" => room.name}, as: :room_name))
         |> put_flash(:info, "Nombre actualizado.")}

      {:error, :not_owner} ->
        {:noreply, put_flash(socket, :error, "Solo el owner puede cambiar el nombre del room.")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "No se pudo guardar el nombre.")}

      _ ->
        {:noreply, put_flash(socket, :error, "No se pudo guardar el nombre.")}
    end
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

  defp mount_room(socket, room_slug, current_user) do
    case Collaboration.get_or_create_accessible_room(room_slug, current_user) do
      {:ok, room} ->
        {:ok,
         socket
         |> assign(:room, room)
         |> assign(:room_id, room.slug)
         |> assign(:shared_users, Collaboration.list_room_users(room))
         |> assign(:room_name_form, to_form(%{"name" => room.name}, as: :room_name))}

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
