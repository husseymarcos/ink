defmodule InkWeb.CodeBlockComponents do
  use Phoenix.Component

  import InkWeb.CoreComponents

  attr :code_block, :map, required: true
  attr :current_user, :any, required: true
  attr :running_info, :map, default: nil
  attr :error, :boolean, default: false

  def code_block(assigns) do
    ~H"""
    <div
      id={"code-block-#{@code_block.id}"}
      class="code-block absolute rounded-xl bg-base-100 shadow-xl ring-1 ring-base-300 overflow-hidden flex flex-col"
      data-code-block-id={@code_block.id}
      data-language={@code_block.language}
      style={
        "left: #{@code_block.x}px; top: #{@code_block.y}px; width: #{@code_block.width}px; z-index: #{@code_block.z_index + 1};"
      }
      phx-hook="CodeBlock"
    >
      <div
        class="code-block-header flex items-center gap-2 px-3 py-2 bg-base-200 border-b border-base-300 cursor-move select-none"
        data-drag-handle
      >
        <.icon name="hero-bars-3" class="h-4 w-4 text-base-content/40 cursor-move" />

        <div class="flex-1 min-w-0">
          <span
            :if={@code_block.name}
            class="text-xs font-medium text-base-content/80 truncate"
          >
            {@code_block.name}
          </span>
        </div>

        <select
          class="select select-ghost select-xs w-auto max-w-[100px] text-xs"
          data-language-select
          phx-change="code_block_language_change"
          phx-value-id={@code_block.id}
        >
          <option value="javascript" selected={@code_block.language == "javascript"}>
            JavaScript
          </option>
          <option value="python" selected={@code_block.language == "python"}>Python</option>
          <option value="plain_text" selected={@code_block.language == "plain_text"}>
            Plain Text
          </option>
        </select>

        <button
          type="button"
          class="btn btn-ghost btn-xs btn-square"
          data-copy-btn
          title="Copiar código"
        >
          <.icon name="hero-clipboard" class="h-3.5 w-3.5" />
        </button>

        <button
          type="button"
          class="btn btn-ghost btn-xs btn-square text-error"
          data-delete-btn
          title="Eliminar bloque"
          phx-click="code_block_delete"
          phx-value-id={@code_block.id}
        >
          <.icon name="hero-trash" class="h-3.5 w-3.5" />
        </button>
      </div>

      <div class="flex-1 flex min-h-0">
        <div class="flex-1 flex flex-col code-editor-container">
          <div class="flex-1 overflow-auto bg-neutral" data-editor-wrapper>
            <textarea
              class="code-editor w-full h-full p-3 bg-transparent text-sm font-mono text-success resize-none focus:outline-none"
              data-code-editor
              spellcheck="false"
              phx-blur="code_block_save"
              phx-value-id={@code_block.id}
            ><%= @code_block.code %></textarea>
          </div>
        </div>

        <div
          :if={@code_block.language != "plain_text"}
          class="output-panel w-48 border-l border-base-300 flex flex-col bg-base-100"
          data-output-panel
        >
          <div class="px-3 py-2 text-xs font-medium text-base-content/60 border-b border-base-300 flex items-center justify-between">
            <span>Output</span>
            <span
              :if={@running_info}
              class="text-info flex items-center gap-1"
            >
              <span class="loading loading-spinner loading-xs"></span>
              {@running_info.email}
            </span>
          </div>
          <div
            class="flex-1 overflow-auto p-3 font-mono text-xs text-base-content"
            data-output-content
          >
            <%= if @error do %>
              <span class="text-error">{@code_block.output}</span>
            <% else %>
              <pre class="whitespace-pre-wrap break-words"><%= @code_block.output || "" %></pre>
            <% end %>
          </div>
        </div>
      </div>

      <div
        :if={@code_block.language != "plain_text"}
        class="code-block-footer flex items-center justify-between px-3 py-2 bg-base-200 border-t border-base-300"
      >
        <div class="flex items-center gap-2">
          <span
            :if={@running_info}
            class="text-xs text-info"
          >
            Ejecutando...
          </span>
        </div>

        <button
          type="button"
          class="btn btn-primary btn-sm gap-1"
          data-run-btn
          disabled={@running_info || @code_block.language == "plain_text"}
          phx-click="code_block_run"
          phx-value-id={@code_block.id}
        >
          <.icon name="hero-play" class="h-3.5 w-3.5" />
          <span>Run</span>
        </button>
      </div>

      <div
        class="resize-handle absolute right-0 top-1/2 -translate-y-1/2 w-2 h-12 bg-base-300/50 hover:bg-base-300 cursor-ew-resize opacity-0 hover:opacity-100 transition-opacity"
        data-resize-handle
      >
      </div>
    </div>
    """
  end

  attr :pyodide_loading, :boolean, default: false

  def code_blocks_toolbar(assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <button
        type="button"
        class="flex items-center justify-center rounded-lg bg-base-200 p-2 text-base-content/80 cursor-pointer hover:bg-base-300 transition-colors"
        phx-click="code_block_create"
        title="Crear bloque de código"
        aria-label="Crear bloque de código"
      >
        <.icon name="hero-code-bracket" class="h-4 w-4" />
      </button>

      <div
        :if={@pyodide_loading}
        class="flex items-center gap-1 rounded-md bg-base-200 px-2 py-1 text-xs text-base-content/60"
        title="Cargando Python..."
      >
        <span class="loading loading-spinner loading-xs"></span>
        <span>Python</span>
      </div>
    </div>
    """
  end
end
