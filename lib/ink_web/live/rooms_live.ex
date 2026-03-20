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
      <div class="mx-auto flex h-full max-w-6xl flex-col gap-8 px-4 py-6 sm:px-6 lg:px-8">
        <header class="flex flex-col gap-6 sm:flex-row sm:items-start sm:justify-between">
          <div class="min-w-0">
            <div class="mb-4 flex items-center gap-3">
              <img
                src={~p"/images/logo.png"}
                alt="Ink"
                class="h-16 w-auto object-contain sm:h-20"
              />
            </div>
            <p class="text-xs font-semibold uppercase tracking-wider text-tertiary">
              Workspace
            </p>
            <h1 class="font-display mt-2 text-3xl font-semibold tracking-[-0.02em] text-foreground sm:text-[2rem]">
              Tus rooms
            </h1>
            <p class="mt-2 max-w-xl text-sm text-muted-foreground">
              Accede rápidamente a los rooms que creaste y a los que te compartieron.
            </p>
          </div>

          <div class="flex shrink-0 items-center gap-3 sm:pt-1">
            <div class="hidden flex-col text-right text-xs sm:flex">
              <span class="font-medium text-foreground">
                {@current_user.email}
              </span>
              <span class="text-[11px] text-muted-foreground">
                Sesión iniciada
              </span>
            </div>

            <.link
              href={~p"/logout"}
              method="delete"
              class="inline-flex items-center gap-1.5 rounded-lg bg-surface-container-low px-3 py-1.5 text-xs font-semibold uppercase tracking-wider text-primary transition hover:bg-primary/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/40"
            >
              <.icon name="hero-arrow-left-on-rectangle" class="h-4 w-4" />
              <span>Cerrar sesión</span>
            </.link>
          </div>
        </header>

        <section class="rounded-2xl bg-surface-container-low p-4 sm:p-6">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div class="flex items-center gap-2">
              <h2 class="font-display text-sm font-semibold text-foreground">Rooms</h2>
              <span class="rounded-full bg-surface-container-highest/80 px-2 py-0.5 text-xs font-medium text-muted-foreground">
                {length(@rooms)} {if length(@rooms) == 1, do: "room", else: "rooms"}
              </span>
            </div>

            <.button
              type="button"
              phx-click="create_room"
              class="inline-flex gap-1.5 px-4 py-2 normal-case tracking-normal"
            >
              <.icon name="hero-plus" class="h-4 w-4" />
              <span>Nuevo room</span>
            </.button>
          </div>

          <div class="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <div
              :if={@rooms == []}
              class="col-span-full rounded-xl bg-surface-container-highest/50 px-3 py-6 text-center text-sm text-muted-foreground"
            >
              Todavía no tienes rooms. Crea uno nuevo o espera a que alguien te comparta uno.
            </div>

            <div
              :for={room <- @rooms}
              class="group relative flex flex-col overflow-hidden rounded-2xl bg-surface-container-lowest transition hover:-translate-y-0.5 hover:bg-white"
            >
              <.link
                navigate={~p"/room/#{room.slug}"}
                class="flex flex-1 flex-col"
              >
                <div class="relative aspect-[4/3] overflow-hidden bg-surface-container-low">
                  <canvas
                    id={"room-preview-#{room.slug}"}
                    phx-hook="RoomPreview"
                    phx-update="ignore"
                    data-strokes={room.preview_strokes_json}
                    data-default-color={Ink.Canvas.default_color()}
                    class="h-full w-full"
                  >
                  </canvas>

                  <div class="pointer-events-none absolute inset-0 bg-gradient-to-t from-surface-container-lowest/80 via-transparent to-transparent opacity-0 transition-opacity duration-200 group-hover:opacity-100">
                  </div>

                  <div class="glass-vellum absolute left-3 top-3 inline-flex items-center gap-1.5 rounded-full px-2 py-0.5 text-[11px] font-medium text-muted-foreground outline-ghost">
                    <span class={[
                      "h-1.5 w-1.5 rounded-full",
                      if(room.online_count > 0,
                        do: "bg-tertiary",
                        else: "bg-surface-container-highest"
                      )
                    ]}>
                    </span>
                    <span>{online_label(room.online_count)}</span>
                  </div>
                </div>

                <div class="px-3 py-2.5">
                  <p class="truncate font-display text-sm font-semibold text-foreground">
                    {room.name}
                  </p>
                  <p class="mt-0.5 truncate text-xs font-mono text-muted-foreground">
                    {room.slug}
                  </p>
                </div>
              </.link>

              <div class="flex items-center justify-between gap-3 px-3 pb-2.5">
                <div class="inline-flex items-center gap-1.5 rounded-full bg-surface-container-low px-2 py-0.5 text-[11px] font-medium text-muted-foreground">
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
                    class="inline-flex items-center justify-center rounded-full p-1 text-xs text-muted-foreground transition hover:bg-primary/10 hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/40"
                    title="Compartir room"
                  >
                    <.icon name="hero-share" class="h-4 w-4" />
                  </button>

                  <button
                    type="button"
                    phx-click="open_delete_modal"
                    phx-value-slug={room.slug}
                    class="inline-flex items-center justify-center rounded-full p-1 text-xs text-error/90 transition hover:bg-error/10 hover:text-error focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-error/40"
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
            <div class="relative overflow-hidden rounded-2xl glass-vellum shadow-ambient outline-ghost">
              <div class="flex items-start justify-between gap-4 bg-surface-container-low/90 px-4 py-3">
                <div>
                  <p class="font-display text-sm font-semibold text-foreground">Compartir room</p>
                  <p class="text-xs text-muted-foreground">
                    Room: <span class="font-mono">{@room_to_share.name}</span>
                    · Código: <span class="font-mono">{@room_to_share.slug}</span>
                  </p>
                </div>
                <button
                  type="button"
                  phx-click="close_share_modal"
                  class="rounded-lg p-1 text-muted-foreground transition hover:bg-surface-container-highest/80 hover:text-foreground"
                  aria-label="Cerrar"
                >
                  <.icon name="hero-x-mark" class="h-5 w-5" />
                </button>
              </div>

              <div class="bg-surface-container-lowest/95 px-4 py-4">
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
                  <.button type="submit" class="sm:mb-2">
                    Compartir
                  </.button>
                </.form>

                <div class="mt-2">
                  <p class="text-xs font-medium text-muted-foreground">Con acceso:</p>
                  <div class="mt-2 flex flex-wrap gap-1.5">
                    <span class="rounded-full bg-primary/10 px-2 py-1 text-xs font-medium text-primary">
                      {@current_user.email} (owner)
                    </span>
                    <span
                      :for={user <- @shared_users}
                      class="rounded-full bg-surface-container-low px-2 py-1 text-xs text-foreground"
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
            <div class="relative overflow-hidden rounded-2xl glass-vellum shadow-ambient outline-ghost">
              <div class="px-4 py-4">
                <p class="font-display text-sm font-semibold text-foreground">Eliminar room</p>
                <p class="mt-1 text-xs text-muted-foreground">
                  Estás a punto de eliminar el room
                  <span class="font-mono font-medium text-foreground">
                    {@room_to_delete.name}
                  </span>
                  ({@room_to_delete.slug}). Esta acción no se puede deshacer.
                </p>

                <div class="mt-4 flex items-center justify-end gap-2">
                  <.button type="button" phx-click="close_delete_modal" variant="secondary" size={:sm}>
                    Cancelar
                  </.button>

                  <.button
                    type="button"
                    phx-click="delete_room"
                    phx-value-slug={@room_to_delete.slug}
                    variant="danger"
                    size={:sm}
                  >
                    Eliminar
                  </.button>
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
