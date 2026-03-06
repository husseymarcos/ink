import * as canvasUtil from "./canvas_draw/canvas.js"

export const RoomPreview = {
  mounted() {
    this.canvas = this.el
    this.ctx = this.canvas.getContext("2d")
    this.defaultColor = this.el.dataset.defaultColor || "#3b82f6"
    this.strokes = []

    const raw = this.el.dataset.strokes
    if (raw) {
      try {
        const parsed = JSON.parse(raw)
        if (Array.isArray(parsed)) {
          this.strokes = parsed
        }
      } catch (e) {
        if (process.env.NODE_ENV === "development") {
          // eslint-disable-next-line no-console
          console.error("Failed to parse room preview strokes", e)
        }
      }
    }

    this._onResize = () => {
      canvasUtil.resizeToContainer(this.canvas, () => this.redrawAll())
    }

    this._onResize()
    window.addEventListener("resize", this._onResize)
  },

  destroyed() {
    if (this._onResize) {
      window.removeEventListener("resize", this._onResize)
    }
  },

  redrawAll() {
    canvasUtil.redrawAll(
      this.ctx,
      this.canvas,
      this.strokes,
      (x, y, color) => canvasUtil.drawPoint(this.ctx, x, y, color ?? this.defaultColor),
      this.defaultColor
    )
  }
}

