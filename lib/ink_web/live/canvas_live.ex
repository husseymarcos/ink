defmodule InkWeb.CanvasLive do
  use InkWeb, :live_view

  alias Ink.Collaboration
  alias Ink.CodeBlocks.CodeBlock
  alias Ink.RoomState
  import InkWeb.CodeBlockComponents

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
    socket = assign(socket, :room, nil)
    socket = assign(socket, :room_id, nil)
    socket = assign(socket, :shared_users, [])
    socket = assign(socket, :share_form, to_form(%{"email" => ""}, as: :share))
    socket = assign(socket, :share_modal_open?, false)
    socket = assign(socket, :room_name_modal_open?, false)
    socket = assign(socket, :room_name_form, to_form(%{"name" => ""}, as: :room_name))
    socket = assign(socket, :code_blocks, [])
    socket = assign(socket, :running_blocks, %{})
    socket = assign(socket, :error_blocks, %{})
    socket = assign(socket, :strokes_above, true)
    socket = assign(socket, :pyodide_loading, false)

    case socket.assigns.current_user do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Sign in to continue.")
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
      <div class="fixed inset-0 z-50 flex flex-col bg-surface" data-canvas-container>
        <div class="pointer-events-none absolute inset-x-0 top-0 z-30 flex items-start justify-between p-3">
          <div class="pointer-events-auto">
            <.link
              navigate={~p"/"}
              class="glass-vellum inline-flex items-center justify-center rounded-full p-1.5 text-sm text-foreground outline-ghost transition hover:bg-surface-container-lowest/90 focus:ring-2 focus:ring-primary/50"
              aria-label="Back to dashboard"
            >
              <.icon name="hero-arrow-left-on-rectangle" class="h-4 w-4" />
            </.link>
          </div>

          <div class="pointer-events-auto relative flex items-start gap-2">
            <button
              type="button"
              phx-click="open_room_name"
              class="group inline-flex items-center justify-end gap-1 rounded-md px-1.5 py-0.5 text-sm font-medium text-muted-foreground transition hover:bg-surface-container-low/90 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/40"
              title="Click to rename"
            >
              <div class="flex flex-col items-end justify-center leading-tight">
                <span class="text-sm font-semibold text-foreground">
                  <span class="font-mono">
                    {if @room, do: @room.name, else: @room_id}
                  </span>
                </span>
              </div>
            </button>

            <div
              :if={@room_name_modal_open?}
              class="absolute right-0 top-12 w-[22rem] rounded-2xl glass-vellum p-4 shadow-ambient outline-ghost"
              role="dialog"
              aria-label="Rename room"
            >
              <div class="flex items-start justify-between gap-3">
                <div>
                  <p class="font-display text-sm font-semibold text-foreground">Room name</p>
                  <p class="text-xs text-muted-foreground">
                    The room code stays the same: <span class="font-mono">{@room_id}</span>
                  </p>
                </div>
                <button
                  type="button"
                  phx-click="close_room_name"
                  class="rounded-lg p-1 text-muted-foreground transition hover:bg-surface-container-highest/80 hover:text-foreground"
                  aria-label="Close"
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
                  label="Name"
                  placeholder={@room_id}
                  required
                />

                <div class="mt-2 flex items-center justify-end gap-2">
                  <.button type="button" phx-click="close_room_name" variant="secondary" size={:sm}>
                    Cancel
                  </.button>
                  <.button type="submit" size={:sm}>
                    Save
                  </.button>
                </div>
              </.form>

              <div class="mt-3 flex items-center justify-between gap-2">
                <p class="text-xs text-muted-foreground">
                  Only the owner can change the room name.
                </p>

                <button
                  type="button"
                  phx-click="open_share_modal"
                  class="inline-flex items-center justify-center gap-1 rounded-md px-2 py-1 text-xs font-medium text-muted-foreground transition hover:bg-primary/10 hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/40"
                >
                  <.icon name="hero-share" class="h-3 w-3" />
                  <span>Share</span>
                </button>
              </div>
            </div>
          </div>
        </div>

        <div
          :if={@share_modal_open?}
          class="fixed inset-0 z-40"
          role="dialog"
          aria-label="Share room"
        >
          <button
            type="button"
            phx-click="close_share_modal"
            class="absolute inset-0 h-full w-full bg-black/40"
            aria-label="Close"
          >
          </button>

          <div class="absolute inset-x-0 top-16 mx-auto w-[min(42rem,calc(100vw-1.5rem))] px-3 sm:top-20">
            <div class="relative overflow-hidden rounded-2xl glass-vellum shadow-ambient outline-ghost">
              <div class="flex items-start justify-between gap-4 bg-surface-container-low/90 px-4 py-3">
                <div>
                  <p class="font-display text-sm font-semibold text-foreground">Share</p>
                  <p class="text-xs text-muted-foreground">
                    Room code: <span class="font-mono">{@room_id}</span>
                  </p>
                </div>
                <button
                  type="button"
                  phx-click="close_share_modal"
                  class="rounded-lg p-1 text-muted-foreground transition hover:bg-surface-container-highest/80 hover:text-foreground"
                  aria-label="Close"
                >
                  <.icon name="hero-x-mark" class="h-5 w-5" />
                </button>
              </div>

              <div class="bg-surface-container-lowest/95 px-4 py-4">
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
                      label="Share by email"
                      placeholder="someone@email.com"
                      required
                    />
                  </div>
                  <.button type="submit" class="sm:mb-2">
                    Share
                  </.button>
                </.form>

                <div class="mt-2">
                  <p class="text-xs font-medium text-muted-foreground">People with access:</p>
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
          :if={@pyodide_loading}
          class="pointer-events-auto fixed left-4 top-4 z-40 flex items-center gap-2 rounded-lg glass-vellum px-3 py-2 shadow-ambient outline-ghost"
        >
          <span
            class="size-5 shrink-0 animate-spin rounded-full border-2 border-primary border-t-transparent"
            aria-hidden="true"
          />
          <span class="text-xs text-muted-foreground">Cargando Python...</span>
        </div>

        <div
          class="absolute inset-0 bg-surface"
          id="canvas-wrapper"
          data-strokes-above={@strokes_above}
        >
          <canvas
            id="ink-canvas"
            phx-hook="CanvasDraw"
            phx-update="ignore"
            data-room-id={@room_id}
            data-user-id={@current_user.id}
            data-user-email={@current_user.email}
            data-default-color={Ink.Canvas.default_color()}
            class="h-full w-full cursor-crosshair touch-none"
          >
          </canvas>

          <div
            id="code-blocks-container"
            class="absolute inset-0 pointer-events-none"
            phx-hook="CodeBlocksContainer"
            data-room-id={@room_id}
          >
            <div
              :for={cb <- @code_blocks}
              class="pointer-events-auto"
            >
              <.code_block
                code_block={cb}
                current_user={@current_user}
                running_info={Map.get(@running_blocks, cb.id)}
                error={Map.get(@error_blocks, cb["id"], false)}
              />
            </div>
          </div>
        </div>

        <div class="pointer-events-auto absolute inset-x-0 bottom-0 z-20 flex justify-center p-3">
          <div
            class="flex items-center justify-between gap-3 rounded-xl glass-vellum p-2 shadow-ambient outline-ghost"
            role="group"
            aria-label="Paleta de colores"
          >
            <div class="flex flex-wrap items-center gap-1.5">
              <%= for color <- @palette do %>
                <button
                  type="button"
                  phx-click="select_color"
                  phx-value-color={color}
                  class={[
                    "h-8 w-8 shrink-0 rounded-lg border-2 transition-all focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 focus:ring-offset-surface",
                    if(@current_color == color,
                      do: "scale-110 border-foreground/30 shadow-md",
                      else: "border-transparent hover:scale-105 hover:shadow"
                    )
                  ]}
                  style={"background-color: #{color}; box-shadow: #{if(color == "#ffffff", do: "inset 0 0 0 1px rgba(0,0,0,0.15)", else: "none")}"}
                  title={color}
                >
                </button>
              <% end %>
            </div>

            <.code_blocks_toolbar pyodide_loading={@pyodide_loading} />
          </div>
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
        {:noreply, put_flash(socket, :error, "Only the owner can change the room name.")}

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
         |> put_flash(:info, "Room shared with #{email}.")
         |> assign(:share_form, to_form(%{"email" => ""}, as: :share))
         |> assign(:shared_users, Collaboration.list_room_users(socket.assigns.room))}

      {:error, :owner_cannot_be_shared} ->
        {:noreply, put_flash(socket, :error, "The owner already has access to this room.")}

      {:error, :not_owner} ->
        {:noreply, put_flash(socket, :error, "Only the owner can share this room.")}

      {:error, :user_not_found} ->
        {:noreply, put_flash(socket, :error, "No user exists with that email.")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :info, "That user already had access.")}

      _ ->
        {:noreply, put_flash(socket, :error, "Could not share the room.")}
    end
  end

  def handle_event("code_block_create", _params, socket) do
    room_id = socket.assigns.room_id

    canvas_width = 800
    canvas_height = 600
    block_width = 400
    x = (canvas_width - block_width) / 2
    y = (canvas_height - 200) / 2

    attrs = %{
      "x" => x,
      "y" => y,
      "language" => "javascript",
      "code" => Map.get(CodeBlock.templates(), "javascript", ""),
      "width" => 400
    }

    case RoomState.create_code_block(room_id, attrs) do
      {:ok, code_block_map} ->
        {:noreply,
         socket
         |> assign(:code_blocks, socket.assigns.code_blocks ++ [code_block_map])}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("code_block_save", %{"id" => id, "value" => code}, socket) do
    room_id = socket.assigns.room_id

    case RoomState.update_code_block(room_id, id, %{"code" => code}) do
      {:ok, code_block_map} ->
        updated_blocks =
          Enum.map(socket.assigns.code_blocks, fn cb ->
            if cb["id"] == id, do: code_block_map, else: cb
          end)

        {:noreply, assign(socket, :code_blocks, updated_blocks)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("code_block_run", %{"id" => id}, socket) do
    code_block = Enum.find(socket.assigns.code_blocks, fn cb -> cb["id"] == id end)

    if code_block && code_block["language"] != "plain_text" do
      {:noreply,
       socket
       |> assign(
         :running_blocks,
         Map.put(socket.assigns.running_blocks, id, %{
           user_id: socket.assigns.current_user.id,
           email: socket.assigns.current_user.email
         })
       )
       |> push_event("code_block_run_request", %{
         id: id,
         code: code_block["code"],
         language: code_block["language"]
       })}
    else
      {:noreply, socket}
    end
  end

  def handle_event(
        "code_block_run_result",
        %{"id" => id, "output" => output, "error" => error},
        socket
      ) do
    room_id = socket.assigns.room_id

    case RoomState.update_output(room_id, id, output) do
      {:ok, code_block_map} ->
        updated_blocks =
          Enum.map(socket.assigns.code_blocks, fn cb ->
            if cb["id"] == id, do: code_block_map, else: cb
          end)

        new_error_blocks =
          if error do
            Map.put(socket.assigns.error_blocks, id, true)
          else
            socket.assigns.error_blocks
          end

        {:noreply,
         socket
         |> assign(:code_blocks, updated_blocks)
         |> assign(:running_blocks, Map.delete(socket.assigns.running_blocks, id))
         |> assign(:error_blocks, new_error_blocks)
         |> push_event("code_block_run_response", %{
           id: id,
           output: output,
           error: error
         })}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("code_block_language_change", params, socket) do
    %{"id" => id, "language" => language} = params
    room_id = socket.assigns.room_id

    case RoomState.change_language(room_id, id, language) do
      {:ok, code_block_map} ->
        updated_blocks =
          Enum.map(socket.assigns.code_blocks, fn cb ->
            if cb["id"] == id, do: code_block_map, else: cb
          end)

        {:noreply,
         socket
         |> assign(:code_blocks, updated_blocks)
         |> push_event("code_block_language_changed", code_block_map)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("code_block_delete", %{"id" => id}, socket) do
    room_id = socket.assigns.room_id

    case RoomState.delete_code_block(room_id, id) do
      {:ok, _} ->
        updated_blocks = Enum.reject(socket.assigns.code_blocks, fn cb -> cb["id"] == id end)

        {:noreply,
         socket
         |> assign(:code_blocks, updated_blocks)
         |> assign(:running_blocks, Map.delete(socket.assigns.running_blocks, id))
         |> assign(:error_blocks, Map.delete(socket.assigns.error_blocks, id))}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("code_block_move", %{"id" => id, "x" => x, "y" => y}, socket) do
    room_id = socket.assigns.room_id

    case RoomState.move_code_block(room_id, id, x, y) do
      {:ok, code_block_map} ->
        updated_blocks =
          Enum.map(socket.assigns.code_blocks, fn cb ->
            if cb["id"] == id, do: code_block_map, else: cb
          end)

        {:noreply, assign(socket, :code_blocks, updated_blocks)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("toggle_strokes_layer", _params, socket) do
    new_strokes_above = !socket.assigns.strokes_above
    {:noreply, assign(socket, :strokes_above, new_strokes_above)}
  end

  @impl true
  def handle_info(%{event: "code_block_inserted", payload: code_block}, socket) do
    if Enum.any?(socket.assigns.code_blocks, fn cb -> cb["id"] == code_block["id"] end) do
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> assign(:code_blocks, socket.assigns.code_blocks ++ [code_block])}
    end
  end

  def handle_info(%{event: "code_block_updated", payload: code_block}, socket) do
    updated_blocks =
      Enum.map(socket.assigns.code_blocks, fn cb ->
        if cb["id"] == code_block["id"], do: code_block, else: cb
      end)

    {:noreply, assign(socket, :code_blocks, updated_blocks)}
  end

  def handle_info(%{event: "code_block_deleted", payload: %{"id" => id}}, socket) do
    updated_blocks = Enum.reject(socket.assigns.code_blocks, fn cb -> cb["id"] == id end)

    {:noreply,
     socket
     |> assign(:code_blocks, updated_blocks)
     |> assign(:running_blocks, Map.delete(socket.assigns.running_blocks, id))
     |> assign(:error_blocks, Map.delete(socket.assigns.error_blocks, id))}
  end

  def handle_info(%{event: "code_block_moved", payload: code_block}, socket) do
    updated_blocks =
      Enum.map(socket.assigns.code_blocks, fn cb ->
        if cb["id"] == code_block["id"], do: code_block, else: cb
      end)

    {:noreply, assign(socket, :code_blocks, updated_blocks)}
  end

  def handle_info(%{event: "code_block_resized", payload: code_block}, socket) do
    updated_blocks =
      Enum.map(socket.assigns.code_blocks, fn cb ->
        if cb["id"] == code_block["id"], do: code_block, else: cb
      end)

    {:noreply, assign(socket, :code_blocks, updated_blocks)}
  end

  def handle_info(%{event: "code_block_language_changed", payload: code_block}, socket) do
    updated_blocks =
      Enum.map(socket.assigns.code_blocks, fn cb ->
        if cb["id"] == code_block["id"], do: code_block, else: cb
      end)

    {:noreply, assign(socket, :code_blocks, updated_blocks)}
  end

  def handle_info(
        %{event: "code_block_running", payload: %{"id" => id, "email" => email}},
        socket
      ) do
    {:noreply,
     socket
     |> assign(
       :running_blocks,
       Map.put(socket.assigns.running_blocks, id, %{
         user_id: "other",
         email: email
       })
     )}
  end

  def handle_info(%{event: "code_block_output", payload: %{}}, socket) do
    {:noreply, socket}
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
         |> put_flash(:error, "You don't have access to that room.")
         |> redirect(to: "/room/#{random_slug()}")}

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Could not open the room.")
         |> redirect(to: "/room/#{random_slug()}")}
    end
  end
end
