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

  drawPoint(x, y) {
    canvas.drawPoint(this.ctx, x, y)
  },

  redrawAll() {
    canvas.redrawAll(this.ctx, this.canvas, this.strokes, (x, y) => this.drawPoint(x, y))
  },

  _getCoords(e) {
    return canvas.getCoords(this.canvas, e)
  },

  _replaceStrokes(strokes) {
    this.strokes = Array.isArray(strokes) ? strokes : []
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
    this._replaceStrokes(nextStrokes)
    this.redrawAll()
    this._updateUndoButton()
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
    if (strokeStart) this.channel.push("start_stroke")
    this.drawPoint(x, y)
    this.channel.push("draw", { x, y })
  },

  undo() {
    this.channel.push("undo").receive("ok", () => {})
  }
}
