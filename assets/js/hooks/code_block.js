import hljs from "highlight.js/lib/core"
import javascript from "highlight.js/lib/languages/javascript"
import python from "highlight.js/lib/languages/python"

hljs.registerLanguage("javascript", javascript)
hljs.registerLanguage("python", python)

export const CodeBlocksContainer = {
  mounted() {
    this.handleEvent("code_block_run_request", (payload) => {
      this._runCode(payload)
    })
  },

  async _runCode(payload) {
    const { id, code, language } = payload

    if (language === "javascript") {
      const result = await InkCodeRunner.runJavaScript(code)
      this.pushEvent("code_block_run_result", {
        id,
        output: result.output,
        error: result.success ? null : result.output
      })
    } else if (language === "python") {
      const result = await InkCodeRunner.runPython(code)
      this.pushEvent("code_block_run_result", {
        id,
        output: result.output,
        error: result.success ? null : result.output
      })
    }
  }
}

export const CodeBlock = {
  mounted() {
    this._setupToolbarDrag()
    this._setupEditor()
    this._setupCopy()
    this._setupDeleteConfirm()
    this._setupResize()
    this._setupKeyboardShortcuts()
  },

  destroyed() {
    this._cleanupDrag()
  },

  handleEvent(event, payload) {
    switch (event) {
      case "code_block_run_response":
        if (payload.id === this.el.dataset.codeBlockId) {
          this._showOutput(payload)
        }
        break

      case "code_block_running":
        if (payload.id === this.el.dataset.codeBlockId) {
          this._showRunningState(payload)
        }
        break

      case "code_block_output":
        if (payload.id === this.el.dataset.codeBlockId) {
          this._showOutput(payload)
        }
        break
    }
  },

  _setupToolbarDrag() {
    // Drag functionality removed - code blocks are now created by clicking the button
  },

  _setupEditor() {
    const editor = this.el.querySelector("[data-code-editor]")
    const wrapper = this.el.querySelector("[data-editor-wrapper]")

    if (!editor) return

    editor.addEventListener("keydown", (e) => {
      if (e.key === "Tab") {
        e.preventDefault()
        const start = editor.selectionStart
        const end = editor.selectionEnd
        editor.value = editor.value.substring(0, start) + "  " + editor.value.substring(end)
        editor.selectionStart = editor.selectionEnd = start + 2
        this._updateHighlighting(editor)
      }
    })

    editor.addEventListener("input", () => {
      this._updateHighlighting(editor)
    })

    this._updateHighlighting(editor)

    const codeBlockId = this.el.dataset.codeBlockId
    if (codeBlockId) {
      this._debounceTimer = null
      editor.addEventListener("input", () => {
        clearTimeout(this._debounceTimer)
        this._debounceTimer = setTimeout(() => {
          this.pushEvent("code_block_save", {
            id: codeBlockId,
            code: editor.value
          })
        }, 1000)
      })
    }
  },

  _updateHighlighting(editor) {
    const language = this.el.dataset.language
    const code = editor.value

    if (language === "plain_text" || !hljs.getLanguage(language)) {
      editor.className = "code-editor w-full h-full p-3 bg-transparent text-sm font-mono text-success resize-none focus:outline-none"
      return
    }

    try {
      const result = hljs.highlight(code, { language })
      editor.className = "code-editor w-full h-full p-3 bg-transparent text-sm font-mono resize-none focus:outline-none"
      editor.style.color = "var(--.hljs-color, #3bd16f)"
    } catch (e) {
      editor.className = "code-editor w-full h-full p-3 bg-transparent text-sm font-mono text-success resize-none focus:outline-none"
    }
  },

  _setupCopy() {
    const copyBtn = this.el.querySelector("[data-copy-btn]")
    const editor = this.el.querySelector("[data-code-editor]")

    if (!copyBtn || !editor) return

    copyBtn.addEventListener("click", async () => {
      try {
        await navigator.clipboard.writeText(editor.value)
        copyBtn.classList.add("text-success")
        setTimeout(() => copyBtn.classList.remove("text-success"), 1000)
      } catch (e) {
        console.error("Failed to copy:", e)
      }
    })
  },

  _setupDeleteConfirm() {
    const deleteBtn = this.el.querySelector("[data-delete-btn]")
    if (!deleteBtn) return

    deleteBtn.addEventListener("click", (e) => {
      e.stopPropagation()
      if (confirm("¿Estás seguro de que quieres eliminar este bloque de código?")) {
        const codeBlockId = this.el.dataset.codeBlockId
        this.pushEvent("code_block_delete", { id: codeBlockId })
      }
    })
  },

  _setupResize() {
    const handle = this.el.querySelector("[data-resize-handle]")
    if (!handle) return

    let isResizing = false
    let startX = 0
    let startWidth = 0

    handle.addEventListener("mousedown", (e) => {
      isResizing = true
      startX = e.clientX
      startWidth = this.el.offsetWidth
      document.body.style.cursor = "ew-resize"
      document.body.style.userSelect = "none"
    })

    document.addEventListener("mousemove", (e) => {
      if (!isResizing) return
      const diff = e.clientX - startX
      const newWidth = Math.max(300, Math.min(800, startWidth + diff))
      this.el.style.width = `${newWidth}px`
    })

    document.addEventListener("mouseup", () => {
      if (!isResizing) return
      isResizing = false
      document.body.style.cursor = ""
      document.body.style.userSelect = ""

      const codeBlockId = this.el.dataset.codeBlockId
      const newWidth = parseInt(this.el.style.width)
      this.pushEvent("code_block_resize", { id: codeBlockId, width: newWidth })
    })
  },

  _setupKeyboardShortcuts() {
    const handleKeydown = (e) => {
      if (e.target.matches("input, textarea, [contenteditable]")) return

      const codeBlockId = this.el.dataset.codeBlockId

      if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
        e.preventDefault()
        this.pushEvent("code_block_run", { id: codeBlockId })
      }

      if (e.key === "Delete" || e.key === "Backspace") {
        if (e.target === this.el || this.el.contains(e.target)) {
        }
      }
    }

    this._keydownHandler = handleKeydown.bind(this)
    document.addEventListener("keydown", this._keydownHandler)
  },

  _cleanupDrag() {
    if (this._keydownHandler) {
      document.removeEventListener("keydown", this._keydownHandler)
    }
  },

  _showRunningState(runningInfo) {
    const footer = this.el.querySelector(".code-block-footer")
    const runBtn = this.el.querySelector("[data-run-btn]")
    if (runBtn) {
      runBtn.disabled = true
      runBtn.innerHTML = '<span class="loading loading-spinner loading-xs"></span> Ejecutando...'
    }
  },

  _showOutput(payload) {
    const runBtn = this.el.querySelector("[data-run-btn]")
    if (runBtn) {
      runBtn.disabled = false
      runBtn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="h-3.5 w-3.5"><path fill-rule="evenodd" d="M4.5 5.653c0-1.426 1.529-2.33 2.779-1.643l11.54 6.348c1.295.712 1.295 2.573 0 3.285L7.28 19.991c-1.25.687-2.779-.217-2.779-1.643V5.653Z" clip-rule="evenodd" /></svg><span>Run</span>'
    }

    const outputContent = this.el.querySelector("[data-output-content]")
    if (outputContent) {
      const isError = payload.error
      if (isError) {
        outputContent.innerHTML = `<span class="text-error">${this._escapeHtml(payload.error)}</span>`
        this.el.classList.add("ring-error")
        setTimeout(() => this.el.classList.remove("ring-error"), 2000)
      } else if (payload.output) {
        outputContent.innerHTML = `<pre class="whitespace-pre-wrap break-words">${this._escapeHtml(payload.output)}</pre>`
      }
    }
  },

  _escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}

window.InkCodeRunner = {
  jsSandbox: null,
  pyodide: null,
  pyodideLoading: false,

  async runJavaScript(code, onOutput) {
    const originalConsole = { ...console }
    let output = ""

    const sandbox = {
      console: {
        log: (...args) => {
          const msg = args.map((a) => (typeof a === "object" ? JSON.stringify(a, null, 2) : String(a))).join(" ")
          output += msg + "\n"
          originalConsole.log(...args)
        },
        error: (...args) => {
          const msg = args.map((a) => (typeof a === "object" ? JSON.stringify(a, null, 2) : String(a))).join(" ")
          output += msg + "\n"
          originalConsole.error(...args)
        },
        warn: (...args) => {
          const msg = args.map((a) => (typeof a === "object" ? JSON.stringify(a, null, 2) : String(a))).join(" ")
          output += msg + "\n"
          originalConsole.warn(...args)
        },
        info: (...args) => {
          const msg = args.map((a) => (typeof a === "object" ? JSON.stringify(a, null, 2) : String(a))).join(" ")
          output += msg + "\n"
          originalConsole.info(...args)
        }
      },
      Math,
      JSON,
      Date,
      Array,
      Object,
      String,
      Number,
      Boolean,
      RegExp,
      Error,
      Map,
      Set,
      WeakMap,
      WeakSet,
      Promise,
      parseInt,
      parseFloat,
      isNaN,
      isFinite,
      encodeURIComponent,
      decodeURIComponent,
      setTimeout: () => {},
      setInterval: () => {},
      clearTimeout: () => {},
      clearInterval: () => {}
    }

    const sandboxKeys = Object.keys(sandbox)
    const sandboxValues = Object.values(sandbox)

    try {
      const fn = new Function(...sandboxKeys, code)
      fn(...sandboxValues)
      return { success: true, output: output.trim() }
    } catch (error) {
      return { success: false, output: error.message }
    }
  },

  async loadPyodide() {
    if (this.pyodide) return this.pyodide
    if (this.pyodideLoading) {
      while (this.pyodideLoading) {
        await new Promise((r) => setTimeout(r, 100))
      }
      return this.pyodide
    }

    this.pyodideLoading = true

    try {
      const script = document.createElement("script")
      script.src = "https://cdn.jsdelivr.net/pyodide/v0.24.1/full/pyodide.js"
      document.head.appendChild(script)

      await new Promise((resolve, reject) => {
        script.onload = resolve
        script.onerror = reject
      })

      this.pyodide = await window.loadPyodide({
        indexURL: "https://cdn.jsdelivr.net/pyodide/v0.24.1/full/"
      })

      return this.pyodide
    } finally {
      this.pyodideLoading = false
    }
  },

  async runPython(code, onOutput) {
    const pyodide = await this.loadPyodide()

    let output = ""

    pyodide.setStdout({
      batched: (msg) => {
        output += msg + "\n"
      }
    })

    pyodide.setStderr({
      batched: (msg) => {
        output += "[stderr] " + msg + "\n"
      }
    })

    try {
      await pyodide.runPythonAsync(code)
      return { success: true, output: output.trim() }
    } catch (error) {
      return { success: false, output: error.message }
    }
  }
}
