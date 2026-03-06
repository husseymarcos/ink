defmodule InkWeb.RoomsLive do
  use InkWeb, :live_view

  alias Ink.Collaboration
  alias Ink.CanvasStore
  alias InkWeb.Presence

  @impl true
  def mount(_params, _session, socket) do
    socket = Phoenix.Component.assign_new(socket, :current_user, fn -> nil end)

    case socket.assigns.current_user do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Inicia sesión para continuar.")
         |> redirect(to: ~p"/login")}

      current_user ->
        {:ok,
         socket
         |> assign(:page_title, "Tus rooms")
         |> assign(:current_user, current_user)
         |> assign(:delete_modal_open?, false)
         |> assign(:room_to_delete, nil)
         |> assign(:share_modal_open?, false)
         |> assign(:share_form, to_form(%{"email" => ""}, as: :share))
         |> assign(:shared_users, [])
         |> assign(:room_to_share, nil)
         |> load_rooms(current_user)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={%{}} current_user={@current_user}>
      <div class="mx-auto flex h-full max-w-6xl flex-col gap-6 px-4 py-6 sm:px-6 lg:px-8">
        <header class="flex items-center justify-between gap-4">
          <div>
            <h1 class="text-lg font-semibold tracking-tight text-base-content sm:text-xl">
              Tus rooms
            </h1>
            <p class="mt-1 text-sm text-base-content/70">
              Accede rápidamente a los rooms que creaste y a los que te compartieron.
            </p>
          </div>

          <div class="flex items-center gap-3">
            <div class="hidden flex-col text-right text-xs sm:flex">
              <span class="font-medium text-base-content">
                {@current_user.email}
              </span>
              <span class="text-[11px] text-base-content/60">
                Sesión iniciada
              </span>
            </div>

            <.link
              href={~p"/logout"}
              method="delete"
              class="inline-flex items-center gap-1.5 rounded-lg border border-base-300 bg-base-100 px-2.5 py-1 text-xs font-medium text-base-content/80 shadow-sm transition hover:border-error/70 hover:bg-error/5 hover:text-error focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-error/60"
            >
              <.icon name="hero-arrow-left-on-rectangle" class="h-4 w-4" />
              <span>Cerrar sesión</span>
            </.link>
          </div>
        </header>

        <section class="rounded-2xl bg-base-100 p-4 shadow-sm ring-1 ring-base-300/70">
          <div class="flex items-center justify-between gap-2">
            <div class="flex items-center gap-2">
              <h2 class="text-sm font-semibold text-base-content">Rooms</h2>
              <span class="rounded-full bg-base-200 px-2 py-0.5 text-xs font-medium text-base-content/70">
                {length(@rooms)} {if length(@rooms) == 1, do: "room", else: "rooms"}
              </span>
            </div>

            <button
              type="button"
              phx-click="create_room"
              class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-3 py-1.5 text-sm font-medium text-primary-content shadow-sm transition hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/60"
            >
              <.icon name="hero-plus" class="h-4 w-4" />
              <span>Nuevo room</span>
            </button>
          </div>

          <div class="mt-3 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <div
              :if={@rooms == []}
              class="col-span-full rounded-xl border border-dashed border-base-300/80 bg-base-100/60 px-3 py-4 text-center text-xs text-base-content/70"
            >
              Todavía no tienes rooms. Crea uno nuevo o espera a que alguien te comparta uno.
            </div>

            <div
              :for={room <- @rooms}
              class="group relative flex flex-col overflow-hidden rounded-2xl border border-base-300/80 bg-base-100/90 shadow-sm transition hover:-translate-y-0.5 hover:border-primary/60 hover:shadow-md"
            >
              <.link
                navigate={~p"/room/#{room.slug}"}
                class="flex flex-1 flex-col"
              >
                <div class="relative aspect-[4/3] overflow-hidden bg-base-200">
                  <canvas
                    id={"room-preview-#{room.slug}"}
                    phx-hook="RoomPreview"
                    phx-update="ignore"
                    data-strokes={room.preview_strokes_json}
                    data-default-color={Ink.Canvas.default_color()}
                    class="h-full w-full"
                  >
                  </canvas>

                  <div class="pointer-events-none absolute inset-0 bg-gradient-to-t from-base-100/70 via-transparent to-transparent opacity-0 transition-opacity duration-200 group-hover:opacity-100">
                  </div>

                  <div class="absolute left-3 top-3 inline-flex items-center gap-1.5 rounded-full bg-base-100/95 px-2 py-0.5 text-[11px] font-medium text-base-content/70 shadow-sm ring-1 ring-base-300/80">
                    <span
                      class={[
                        "h-1.5 w-1.5 rounded-full",
                        if(room.online_count > 0, do: "bg-emerald-400", else: "bg-base-300")
                      ]}
                    >
                    </span>
                    <span>{online_label(room.online_count)}</span>
                  </div>
                </div>

                <div class="px-3 py-2.5">
                  <p class="truncate text-sm font-semibold text-base-content">
                    {room.name}
                  </p>
                  <p class="mt-0.5 truncate text-xs font-mono text-base-content/60">
                    {room.slug}
                  </p>
                </div>
              </.link>

              <div class="flex items-center justify-between gap-3 px-3 pb-2.5">
                <div class="inline-flex items-center gap-1.5 rounded-full bg-base-200 px-2 py-0.5 text-[11px] font-medium text-base-content/70">
                  <.icon
                    :if={room.kind == :owned}
                    name="hero-user"
                    class="h-3.5 w-3.5"
                  />
                  <.icon
                    :if={room.kind == :shared}
                    name="hero-user-group"
                    class="h-3.5 w-3.5"
                  />
                  <span>
                    <%= if room.kind == :owned do %>
                      Tu room
                    <% else %>
                      Compartido ·
                      <span class="font-mono">
                        {room.owner && room.owner.email}
                      </span>
                    <% end %>
                  </span>
                </div>

                <div
                  :if={room.kind == :owned}
                  class="flex items-center gap-1.5"
                >
                  <button
                    type="button"
                    phx-click="open_share_modal"
                    phx-value-slug={room.slug}
                    class="inline-flex items-center justify-center rounded-full p-1 text-xs text-base-content/70 transition hover:bg-base-200 hover:text-base-content focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/70"
                    title="Compartir room"
                  >
                    <.icon name="hero-share" class="h-4 w-4" />
                  </button>

                  <button
                    type="button"
                    phx-click="open_delete_modal"
                    phx-value-slug={room.slug}
                    class="inline-flex items-center justify-center rounded-full p-1 text-xs text-red-500/80 transition hover:bg-red-50 hover:text-red-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-red-500/70"
                    title="Eliminar room"
                  >
                    <.icon name="hero-trash" class="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </section>

        <div
          :if={@share_modal_open? && @room_to_share}
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
                  <p class="text-sm font-semibold text-base-content">Compartir room</p>
                  <p class="text-xs text-base-content/60">
                    Room: <span class="font-mono">{@room_to_share.name}</span> · Código:
                    <span class="font-mono">{@room_to_share.slug}</span>
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
                  id="dashboard-share-room-form"
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

        <div
          :if={@delete_modal_open? && @room_to_delete}
          class="fixed inset-0 z-40"
          role="dialog"
          aria-label="Eliminar room"
        >
          <button
            type="button"
            phx-click="close_delete_modal"
            class="absolute inset-0 h-full w-full bg-black/40"
            aria-label="Cerrar"
          >
          </button>

          <div class="absolute inset-x-0 top-20 mx-auto w-[min(30rem,calc(100vw-1.5rem))] px-3">
            <div class="relative overflow-hidden rounded-2xl bg-base-100 shadow-2xl ring-1 ring-base-300">
              <div class="px-4 py-4">
                <p class="text-sm font-semibold text-base-content">Eliminar room</p>
                <p class="mt-1 text-xs text-base-content/70">
                  Estás a punto de eliminar el room
                  <span class="font-mono font-medium text-base-content">
                    {@room_to_delete.name}
                  </span>
                  ({@room_to_delete.slug}). Esta acción no se puede deshacer.
                </p>

                <div class="mt-4 flex items-center justify-end gap-2">
                  <button
                    type="button"
                    phx-click="close_delete_modal"
                    class="btn btn-ghost btn-sm"
                  >
                    Cancelar
                  </button>

                  <button
                    type="button"
                    phx-click="delete_room"
                    phx-value-slug={@room_to_delete.slug}
                    class="btn btn-error btn-sm"
                  >
                    Eliminar
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp load_rooms(socket, %{} = current_user) do
    owned_rooms =
      current_user
      |> Collaboration.list_owned_rooms()
      |> Enum.map(&enhance_room/1)
      |> Enum.map(&Map.put(&1, :kind, :owned))

    shared_rooms =
      current_user
      |> Collaboration.list_shared_rooms()
      |> Enum.map(&enhance_room/1)
      |> Enum.map(&Map.put(&1, :kind, :shared))

    rooms = owned_rooms ++ shared_rooms

    socket
    |> assign(:owned_rooms, owned_rooms)
    |> assign(:shared_rooms, shared_rooms)
    |> assign(:rooms, rooms)
  end

  defp enhance_room(room) do
    strokes = CanvasStore.get_strokes(room.slug)
    preview_strokes_json = Phoenix.json_library().encode!(strokes)

    online_count =
      "canvas:room:#{room.slug}"
      |> Presence.list()
      |> map_size()

    room
    |> Map.put(:preview_strokes_json, preview_strokes_json)
    |> Map.put(:online_count, online_count)
  end

  defp online_label(0), do: "Sin personas conectadas"
  defp online_label(1), do: "1 persona conectada"
  defp online_label(n), do: "#{n} personas conectadas"

  defp random_slug do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
    |> String.downcase()
  end

  @impl true
  def handle_event("create_room", _params, socket) do
    slug = random_slug()

    case Collaboration.create_room(slug, socket.assigns.current_user) do
      {:ok, room} ->
        {:noreply, push_navigate(socket, to: ~p"/room/#{room.slug}")}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "No se pudo crear el room. Inténtalo nuevamente.")}
    end
  end

  def handle_event("open_delete_modal", %{"slug" => slug}, socket) do
    case Collaboration.get_room_by_slug(slug) do
      nil ->
        {:noreply, put_flash(socket, :error, "Room no encontrado.")}

      room ->
        {:noreply,
         socket
         |> assign(:room_to_delete, room)
         |> assign(:delete_modal_open?, true)}
    end
  end

  def handle_event("close_delete_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:delete_modal_open?, false)
     |> assign(:room_to_delete, nil)}
  end

  def handle_event("delete_room", %{"slug" => slug}, socket) do
    current_user = socket.assigns.current_user

    case Collaboration.get_room_by_slug(slug) do
      nil ->
        {:noreply, put_flash(socket, :error, "Room no encontrado.")}

      room ->
        case Collaboration.delete_room(room, current_user) do
          {:ok, _room} ->
            {:noreply,
             socket
             |> put_flash(:info, "Room eliminado.")
             |> assign(:delete_modal_open?, false)
             |> assign(:room_to_delete, nil)
             |> load_rooms(current_user)}

          {:error, :not_owner} ->
            {:noreply, put_flash(socket, :error, "Solo el owner puede eliminar este room.")}

          {:error, _error} ->
            {:noreply, put_flash(socket, :error, "No se pudo eliminar el room.")}
        end
    end
  end

  def handle_event("open_share_modal", %{"slug" => slug}, socket) do
    case Collaboration.get_room_by_slug(slug) do
      nil ->
        {:noreply, put_flash(socket, :error, "Room no encontrado.")}

      room ->
        {:noreply,
         socket
         |> assign(:room_to_share, room)
         |> assign(:share_modal_open?, true)
         |> assign(:share_form, to_form(%{"email" => ""}, as: :share))
         |> assign(:shared_users, Collaboration.list_room_users(room))}
    end
  end

  def handle_event("close_share_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:share_modal_open?, false)
     |> assign(:room_to_share, nil)}
  end

  def handle_event("share_room", %{"share" => %{"email" => email}}, socket) do
    current_user = socket.assigns.current_user
    room = socket.assigns.room_to_share

    case Collaboration.share_room_with_email(room, current_user, email) do
      {:ok, _membership} ->
        {:noreply,
         socket
         |> put_flash(:info, "Room compartido con #{email}.")
         |> assign(:share_form, to_form(%{"email" => ""}, as: :share))
         |> assign(:shared_users, Collaboration.list_room_users(room))}

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
end


