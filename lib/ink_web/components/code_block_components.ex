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
      class="code-block absolute flex flex-col overflow-hidden rounded-xl bg-surface-container-lowest shadow-ambient outline-ghost"
      data-code-block-id={@code_block.id}
      data-language={@code_block.language}
      style={
        "left: #{@code_block.x}px; top: #{@code_block.y}px; width: #{@code_block.width}px; z-index: #{@code_block.z_index + 1};"
      }
      phx-hook="CodeBlock"
    >
      <div
        class="code-block-header flex cursor-move select-none items-center gap-2 bg-surface-container-low px-3 py-2"
        data-drag-handle
      >
        <.icon name="hero-bars-3" class="h-4 w-4 cursor-move text-muted-foreground" />

        <div class="flex-1 min-w-0">
          <span
            :if={@code_block.name}
            class="truncate text-xs font-medium text-muted-foreground"
          >
            {@code_block.name}
          </span>
        </div>

        <select
          class="ink-select w-auto max-w-[100px] cursor-pointer rounded-lg border-0 bg-surface-container-low px-2 py-1 text-xs text-foreground"
          name="language"
          phx-change="code_block_language_change"
          phx-value-id={@code_block.id}
        >
          <option value="javascript" selected={@code_block.language == "javascript"}>
            JavaScript
          </option>
          <option value="python" selected={@code_block.language == "python"}>Python</option>
        </select>

        <.button
          type="button"
          variant="secondary"
          size={:xs}
          square
          data-copy-btn
          title="Copy code"
        >
          <.icon name="hero-clipboard" class="h-3.5 w-3.5" />
        </.button>

        <.button
          type="button"
          variant="secondary"
          size={:xs}
          square
          class="text-error"
          data-delete-btn
          title="Delete block"
        >
          <.icon name="hero-trash" class="h-3.5 w-3.5" />
        </.button>
      </div>

      <div class="flex-1 flex min-h-0">
        <div class="flex-1 flex flex-col code-editor-container">
          <div class="flex-1 overflow-auto bg-neutral" data-editor-wrapper>
            <textarea
              id={"editor-#{@code_block.id}"}
              class="code-editor w-full h-full p-3 bg-transparent text-sm font-mono text-success resize-none focus:outline-none"
              data-code-editor
              spellcheck="false"
              phx-blur="code_block_save"
              phx-value-id={@code_block.id}
              phx-update="ignore"
            ><%= @code_block.code %></textarea>
          </div>
        </div>

        <div
          class="output-panel flex w-48 flex-col bg-surface-container-low pl-3"
          data-output-panel
        >
          <div class="flex items-center justify-between bg-surface-container-highest/60 px-3 py-2 text-xs font-medium text-muted-foreground">
            <span>Output</span>
            <span
              :if={@running_info}
              class="text-info flex items-center gap-1"
            >
              <span
                class="size-3.5 shrink-0 animate-spin rounded-full border-2 border-primary border-t-transparent"
                aria-hidden="true"
              />
              {@running_info.email}
            </span>
          </div>
          <div
            class="flex-1 overflow-auto p-3 font-mono text-xs text-foreground"
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

      <div class="code-block-footer flex items-center justify-between bg-surface-container-low px-3 py-2">
        <div class="flex items-center gap-2">
          <span
            :if={@running_info}
            class="text-xs text-info"
          >
            Running...
          </span>
        </div>

        <.button
          type="button"
          size={:sm}
          class="gap-1"
          data-run-btn
          disabled={@running_info}
          phx-click="code_block_run"
          phx-value-id={@code_block.id}
        >
          <.icon name="hero-play" class="h-3.5 w-3.5" />
          <span>Run</span>
        </.button>
      </div>

      <div
        class="resize-handle absolute right-0 top-1/2 h-12 w-2 -translate-y-1/2 cursor-ew-resize bg-surface-container-highest/80 opacity-0 transition-opacity hover:bg-surface-container-highest hover:opacity-100"
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
        class="flex cursor-pointer items-center justify-center rounded-lg bg-surface-container-low p-2 text-muted-foreground transition-colors hover:bg-surface-container-highest/80 hover:text-foreground"
        phx-click="code_block_create"
        title="Create code block"
        aria-label="Create code block"
      >
        <.icon name="hero-code-bracket" class="h-4 w-4" />
      </button>

      <div
        :if={@pyodide_loading}
        class="flex items-center gap-1 rounded-md bg-surface-container-low px-2 py-1 text-xs text-muted-foreground"
        title="Loading Python..."
      >
        <span
          class="size-3.5 shrink-0 animate-spin rounded-full border-2 border-primary border-t-transparent"
          aria-hidden="true"
        />
        <span>Python</span>
      </div>
    </div>
    """
  end
end
