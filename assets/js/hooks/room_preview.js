const PADDING = 8
const POINT_RADIUS_PREVIEW = 2
const LINE_WIDTH_PREVIEW = POINT_RADIUS_PREVIEW * 2

function parseStrokes(raw) {
  if (!raw) return []
  try {
    const parsed = JSON.parse(raw)
    return Array.isArray(parsed) ? parsed : []
  } catch (_e) {
    return []
  }
}

function allPoints(strokes) {
  const out = []
  for (const stroke of strokes) {
    const points = stroke.points || stroke
    if (Array.isArray(points)) {
      for (const p of points) {
        const x = Number(p.x ?? p["x"])
        const y = Number(p.y ?? p["y"])
        if (Number.isFinite(x) && Number.isFinite(y)) out.push({ x, y })
      }
    }
  }
  return out
}

function boundingBox(points) {
  if (points.length === 0) return null
  let minX = Infinity,
    minY = Infinity,
    maxX = -Infinity,
    maxY = -Infinity
  for (const p of points) {
    minX = Math.min(minX, p.x)
    minY = Math.min(minY, p.y)
    maxX = Math.max(maxX, p.x)
    maxY = Math.max(maxY, p.y)
  }
  return { minX, minY, maxX, maxY }
}

function drawPointScaled(ctx, x, y, color) {
  if (!ctx) return
  const px = Number(x)
  const py = Number(y)
  ctx.beginPath()
  ctx.arc(px, py, POINT_RADIUS_PREVIEW, 0, 2 * Math.PI)
  ctx.fillStyle = color
  ctx.fill()
}

function drawLineScaled(ctx, x0, y0, x1, y1, color) {
  if (!ctx) return
  ctx.beginPath()
  ctx.moveTo(Number(x0), Number(y0))
  ctx.lineTo(Number(x1), Number(y1))
  ctx.strokeStyle = color
  ctx.lineWidth = LINE_WIDTH_PREVIEW
  ctx.lineCap = "round"
  ctx.lineJoin = "round"
  ctx.stroke()
}

export const RoomPreview = {
  mounted() {
    this.canvas = this.el
    this.ctx = this.canvas.getContext("2d")
    this.defaultColor = this.el.dataset.defaultColor || "#3b82f6"
    this.strokes = parseStrokes(this.el.dataset.strokes)

    const resizeAndDraw = () => {
      const container = this.canvas?.parentElement
      if (!container) return
      const w = container.clientWidth
      const h = container.clientHeight
      if (w <= 0 || h <= 0) return
      if (this.canvas.width !== w || this.canvas.height !== h) {
        this.canvas.width = w
        this.canvas.height = h
      }
      this.redrawAll()
    }

    this._resizeAndDraw = resizeAndDraw
    this._onWindowResize = () => requestAnimationFrame(() => this._resizeAndDraw())

    const container = this.canvas.parentElement
    if (container) {
      this._resizeObserver = new ResizeObserver(this._onWindowResize)
      this._resizeObserver.observe(container)
    }
    window.addEventListener("resize", this._onWindowResize)

    requestAnimationFrame(() => this._resizeAndDraw())
  },

  destroyed() {
    if (this._onWindowResize) {
      window.removeEventListener("resize", this._onWindowResize)
    }
    if (this._resizeObserver && this.canvas?.parentElement) {
      this._resizeObserver.unobserve(this.canvas.parentElement)
    }
  },

  redrawAll() {
    const ctx = this.ctx
    const canvas = this.canvas
    if (!ctx || !canvas || canvas.width <= 0 || canvas.height <= 0) return

    ctx.clearRect(0, 0, canvas.width, canvas.height)

    const points = allPoints(this.strokes)
    const bbox = boundingBox(points)

    if (!bbox || points.length === 0) return

    const rangeX = bbox.maxX - bbox.minX || 1
    const rangeY = bbox.maxY - bbox.minY || 1
    const scale = Math.min(
      (canvas.width - 2 * PADDING) / rangeX,
      (canvas.height - 2 * PADDING) / rangeY
    )
    const tx = PADDING - bbox.minX * scale
    const ty = PADDING - bbox.minY * scale

    ctx.save()
    ctx.translate(tx, ty)
    ctx.scale(scale, scale)

    for (const stroke of this.strokes) {
      const pts = stroke.points || stroke
      const color = stroke.color || this.defaultColor
      if (!Array.isArray(pts)) continue
      if (pts.length === 0) continue
      if (pts.length === 1) {
        const p = pts[0]
        const x = Number(p.x ?? p["x"])
        const y = Number(p.y ?? p["y"])
        if (Number.isFinite(x) && Number.isFinite(y)) {
          drawPointScaled(ctx, x, y, color)
        }
      } else {
        for (let i = 0; i < pts.length - 1; i++) {
          const a = pts[i]
          const b = pts[i + 1]
          const x0 = Number(a.x ?? a["x"])
          const y0 = Number(a.y ?? a["y"])
          const x1 = Number(b.x ?? b["x"])
          const y1 = Number(b.y ?? b["y"])
          if (Number.isFinite(x0) && Number.isFinite(y0) && Number.isFinite(x1) && Number.isFinite(y1)) {
            drawLineScaled(ctx, x0, y0, x1, y1, color)
          }
        }
      }
    }

    ctx.restore()
  }
}
