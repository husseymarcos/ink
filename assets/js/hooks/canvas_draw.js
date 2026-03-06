import * as canvas from "./canvas_draw/canvas.js"
import * as channel from "./canvas_draw/channel.js"
import * as pointer from "./canvas_draw/pointer.js"
import * as undo from "./canvas_draw/undo.js"

export const CanvasDraw = {
  mounted() {
    this._initState()
    this._setupCanvas()
    this._setupResize()

    const roomId = this.el.dataset.roomId
    if (!roomId) return

    this.handleEvent("set_color", ({ color }) => {
      if (color) this.currentColor = color
    })

    this.channel = channel.connectChannel(roomId)
    channel.setupChannelHandlers(this.channel, this)
    pointer.setupPointerListeners(this.canvas, this)

    this.undoButton = undo.setupUndoButton(this.el, () => this.undo())
    this._handleKeydown = (e) => this._onKeydown(e)
    undo.setupKeyboard(this._handleKeydown)
  },

  destroyed() {
    document.removeEventListener("keydown", this._handleKeydown)
    if (this._boundResize) window.removeEventListener("resize", this._boundResize)
  },

  _initState() {
    this.canvas = this.el
    this.ctx = this.canvas.getContext("2d")
    this.drawing = false
    this.strokes = []
    this.currentColor = this.el.dataset.defaultColor
    this.currentUserId = this.el.dataset.userId || null
    this.currentUserEmail = this.el.dataset.userEmail || null
    this.cursors = {}
    this.cursorContainer = this.canvas.parentElement
  },

  _setupCanvas() {
    canvas.resizeToContainer(this.canvas, () => this.redrawAll())
  },

  _resizeCanvas() {
    canvas.resizeToContainer(this.canvas, () => this.redrawAll())
  },

  _setupResize() {
    this._boundResize = this._resizeCanvas.bind(this)
    window.addEventListener("resize", this._boundResize)
  },

  drawPoint(x, y, color) {
    canvas.drawPoint(this.ctx, x, y, color ?? this.currentColor)
  },

  redrawAll() {
    canvas.redrawAll(
      this.ctx,
      this.canvas,
      this.strokes,
      (x, y, color) => this.drawPoint(x, y, color),
      this.currentColor
    )
  },

  _replaceStrokes(strokes) {
    this.strokes = Array.isArray(strokes)
      ? strokes.map((s) => (s && s.points ? s : { points: s, color: this.currentColor }))
      : []
  },

  _updateUndoButton() {
    undo.updateUndoButton(this.undoButton, this.strokes.length)
  },

  _onJoinOk(resp) {
    this._replaceStrokes((resp?.strokes) ?? [])
    this._resizeCanvas()
    this.redrawAll()
    this._updateUndoButton()
  },

  _onDrawPoint({ x, y, stroke_start, color }) {
    const point = { x: Number(x), y: Number(y) }
    const strokeColor = color || this.currentColor
    if (stroke_start) {
      this.strokes.push({ points: [point], color: strokeColor })
    } else {
      if (this.strokes.length === 0) this.strokes.push({ points: [], color: strokeColor })
      const last = this.strokes[this.strokes.length - 1]
      last.points.push(point)
    }
    this.drawPoint(x, y, strokeColor)
    this._updateUndoButton()
  },

  _onStrokesReplaced({ strokes }) {
    const nextStrokes = Array.isArray(strokes) ? strokes : []
    this._replaceStrokes(nextStrokes)
    this.redrawAll()
    this._updateUndoButton()
  },

  _cursorColorFor(userId) {
    // Deterministic pseudo-random color based on user id
    const colors = [
      "#1e293b",
      "#dc2626",
      "#ea580c",
      "#ca8a04",
      "#16a34a",
      "#0891b2",
      "#3b82f6",
      "#7c3aed",
      "#db2777"
    ]
    if (!userId) return colors[0]
    const str = String(userId)
    let hash = 0
    for (let i = 0; i < str.length; i++) {
      hash = (hash * 31 + str.charCodeAt(i)) >>> 0
    }
    return colors[hash % colors.length]
  },

  _ensureCursorElement(userId, email) {
    if (!this.cursorContainer) return null

    let cursor = this.cursors[userId]
    if (cursor?.el && cursor.labelEl) return cursor

    const color = this._cursorColorFor(userId)
    const wrapper = document.createElement("div")
    wrapper.className =
      "pointer-events-none absolute z-30 -translate-x-1/2 -translate-y-1/2 flex items-center gap-1 transition-transform duration-75"

    const dot = document.createElement("div")
    dot.className = "h-3 w-3 rounded-full border border-white shadow"
    dot.style.backgroundColor = color

    const label = document.createElement("div")
    label.className =
      "rounded-md bg-base-100/95 px-1.5 py-0.5 text-[11px] font-medium text-base-content shadow-sm border border-base-200"
    const name = (email || "").split("@")[0] || "Anon"
    label.textContent = name

    wrapper.appendChild(dot)
    wrapper.appendChild(label)
    this.cursorContainer.appendChild(wrapper)

    cursor = { el: wrapper, labelEl: label }
    this.cursors[userId] = cursor
    return cursor
  },

  _onCursorPosition({ x, y, user_id, email }) {
    if (user_id == null || x == null || y == null) return
    if (this.currentUserId && String(user_id) === String(this.currentUserId)) return
    if (!this.canvas || !this.cursorContainer) return

    const cursor = this._ensureCursorElement(user_id, email)
    if (!cursor || !cursor.el) return

    const canvasWidth = this.canvas.width || 1
    const canvasHeight = this.canvas.height || 1
    const leftPercent = (Number(x) / canvasWidth) * 100
    const topPercent = (Number(y) / canvasHeight) * 100

    cursor.el.style.left = `${leftPercent}%`
    cursor.el.style.top = `${topPercent}%`
  },

  _onKeydown(e) {
    const isUndo = (e.metaKey || e.ctrlKey) && e.key === "z"
    const ignoreTarget = e.target.matches("input, textarea, [contenteditable]")
    if (isUndo && !ignoreTarget) {
      e.preventDefault()
      this.undo()
    }
  },

  _sendPoint(x, y, strokeStart) {
    if (strokeStart) this.channel.push("start_stroke", { color: this.currentColor })
    this.drawPoint(x, y)
    this.channel.push("draw", { x, y })
  },

  _sendCursor(x, y) {
    if (!this.channel) return
    this.channel.push("cursor_move", { x, y })
  },

  undo() {
    this.channel.push("undo").receive("ok", () => {})
  }
}
