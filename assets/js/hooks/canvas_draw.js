import { Socket } from "phoenix"

const UNDO_DELAY_MS = 1000
const POINT_RADIUS = 4
const STROKE_COLOR = "#3b82f6"

export const CanvasDraw = {
  mounted() {
    this._initState()
    this._setupCanvas()
    this._setupResize()

    const roomId = this.el.dataset.roomId
    if (!roomId) return

    this._connectChannel(roomId)
    this._setupChannelHandlers()
    this._setupPointerListeners()
    this._setupUndoButton()
    this._setupKeyboard()
  },

  destroyed() {
    document.removeEventListener("keydown", this._handleKeydown)
    if (this._boundResize) window.removeEventListener("resize", this._boundResize)
    if (this._undoApplyTimeout) clearTimeout(this._undoApplyTimeout)
  },

  // --- State ---

  _initState() {
    this.canvas = this.el
    this.ctx = this.canvas.getContext("2d")
    this.drawing = false
    this.strokes = []
    this._undoApplyTimeout = null
  },

  // --- Canvas size & drawing ---

  _setupCanvas() {
    this._resizeCanvas()
  },

  _resizeCanvas() {
    const container = this.canvas?.parentElement
    if (!container) return
    const w = container.clientWidth
    const h = container.clientHeight
    if (this.canvas.width !== w || this.canvas.height !== h) {
      this.canvas.width = w
      this.canvas.height = h
      this.redrawAll()
    }
  },

  _setupResize() {
    this._boundResize = this._resizeCanvas.bind(this)
    window.addEventListener("resize", this._boundResize)
  },

  drawPoint(x, y) {
    if (!this.ctx) return
    const px = Number(x)
    const py = Number(y)
    this.ctx.beginPath()
    this.ctx.arc(px, py, POINT_RADIUS, 0, 2 * Math.PI)
    this.ctx.fillStyle = STROKE_COLOR
    this.ctx.fill()
  },

  redrawAll() {
    if (!this.ctx || !this.canvas) return
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
    for (const stroke of this.strokes) {
      for (const p of stroke) {
        this.drawPoint(p.x, p.y)
      }
    }
  },

  // --- Coordinates ---

  _getCoords(e) {
    const rect = this.canvas.getBoundingClientRect()
    const scaleX = this.canvas.width / rect.width
    const scaleY = this.canvas.height / rect.height
    return {
      x: Math.round((e.clientX - rect.left) * scaleX),
      y: Math.round((e.clientY - rect.top) * scaleY)
    }
  },

  // --- Channel ---

  _connectChannel(roomId) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
    const socket = new Socket("/socket", { params: { _csrf_token: csrfToken } })
    socket.connect()
    this.channel = socket.channel(`canvas:room:${roomId}`, {})
  },

  _setupChannelHandlers() {
    const { channel } = this

    channel.join()
      .receive("ok", (resp) => this._onJoinOk(resp))
      .receive("error", (resp) => console.error("Canvas channel join failed", resp))

    channel.on("draw_point", (payload) => this._onDrawPoint(payload))
    channel.on("strokes_replaced", (payload) => this._onStrokesReplaced(payload))
  },

  _onJoinOk(resp) {
    this._replaceStrokes((resp?.strokes) ?? [])
    this._resizeCanvas()
    this.redrawAll()
    this._updateUndoButton()
  },

  _onDrawPoint({ x, y, stroke_start }) {
    const point = { x: Number(x), y: Number(y) }
    if (stroke_start) {
      this.strokes.push([point])
    } else {
      if (this.strokes.length === 0) this.strokes.push([])
      this.strokes[this.strokes.length - 1].push(point)
    }
    this.drawPoint(x, y)
    this._updateUndoButton()
  },

  _onStrokesReplaced({ strokes }) {
    const nextStrokes = Array.isArray(strokes) ? strokes : []
    if (this._undoApplyTimeout) clearTimeout(this._undoApplyTimeout)
    this._undoApplyTimeout = setTimeout(() => {
      this._undoApplyTimeout = null
      this._replaceStrokes(nextStrokes)
      this.redrawAll()
      this._updateUndoButton()
    }, UNDO_DELAY_MS)
  },

  _replaceStrokes(strokes) {
    this.strokes = Array.isArray(strokes) ? strokes : []
  },

  // --- Pointer (mouse/touch) ---

  _setupPointerListeners() {
    this.canvas.addEventListener("mousedown", this._onPointerDown.bind(this))
    this.canvas.addEventListener("mousemove", this._onPointerMove.bind(this))
    this.canvas.addEventListener("mouseup", this._onPointerUp.bind(this))
    this.canvas.addEventListener("mouseleave", this._onPointerUp.bind(this))
  },

  _onPointerDown(e) {
    this.drawing = true
    const { x, y } = this._getCoords(e)
    this._sendPoint(x, y, true)
  },

  _onPointerMove(e) {
    if (!this.drawing) return
    const { x, y } = this._getCoords(e)
    this._sendPoint(x, y, false)
  },

  _onPointerUp() {
    this.drawing = false
  },

  _sendPoint(x, y, strokeStart) {
    if (strokeStart) this.channel.push("start_stroke")
    this.drawPoint(x, y)
    this.channel.push("draw", { x, y })
  },

  // --- Undo ---

  _setupUndoButton() {
    const btn = this.el.closest("[data-canvas-container]")?.querySelector("[data-canvas-undo]")
    if (!btn) return
    this.undoButton = btn
    btn.addEventListener("click", (e) => {
      e.preventDefault()
      this.undo()
    })
  },

  _setupKeyboard() {
    this._handleKeydown = this._handleKeydown.bind(this)
    document.addEventListener("keydown", this._handleKeydown)
  },

  _handleKeydown(e) {
    const isUndo = (e.metaKey || e.ctrlKey) && e.key === "z"
    const ignoreTarget = e.target.matches("input, textarea, [contenteditable]")
    if (isUndo && !ignoreTarget) {
      e.preventDefault()
      this.undo()
    }
  },

  undo() {
    this.channel.push("undo").receive("ok", () => {})
  },

  _updateUndoButton() {
    if (this.undoButton) {
      this.undoButton.disabled = this.strokes.length === 0
    }
  }
}
