const POINT_RADIUS = 4
const LINE_WIDTH = POINT_RADIUS * 2

export function drawPoint(ctx, x, y, color) {
  if (!ctx) return
  const px = Number(x)
  const py = Number(y)
  ctx.beginPath()
  ctx.arc(px, py, POINT_RADIUS, 0, 2 * Math.PI)
  ctx.fillStyle = color
  ctx.fill()
}

export function drawLine(ctx, x0, y0, x1, y1, color) {
  if (!ctx) return
  ctx.beginPath()
  ctx.moveTo(Number(x0), Number(y0))
  ctx.lineTo(Number(x1), Number(y1))
  ctx.strokeStyle = color
  ctx.lineWidth = LINE_WIDTH
  ctx.lineCap = "round"
  ctx.lineJoin = "round"
  ctx.stroke()
}

export function redrawAll(ctx, canvas, strokes, drawPointFn, drawLineFn, defaultColor) {
  if (!ctx || !canvas) return
  ctx.clearRect(0, 0, canvas.width, canvas.height)
  for (const stroke of strokes) {
    const points = stroke.points || stroke
    const color = stroke.color || defaultColor
    if (points.length === 0) continue
    if (points.length === 1) {
      drawPointFn(points[0].x, points[0].y, color)
    } else {
      for (let i = 0; i < points.length - 1; i++) {
        const a = points[i]
        const b = points[i + 1]
        drawLineFn(a.x, a.y, b.x, b.y, color)
      }
    }
  }
}

export function resizeToContainer(canvas, onResize) {
  const container = canvas?.parentElement
  if (!container) return false
  const w = container.clientWidth
  const h = container.clientHeight
  if (canvas.width !== w || canvas.height !== h) {
    canvas.width = w
    canvas.height = h
    onResize()
    return true
  }
  return false
}

export function getCoords(canvas, e) {
  const rect = canvas.getBoundingClientRect()
  const scaleX = canvas.width / rect.width
  const scaleY = canvas.height / rect.height
  return {
    x: Math.round((e.clientX - rect.left) * scaleX),
    y: Math.round((e.clientY - rect.top) * scaleY)
  }
}

export function getCoordsFromTouch(canvas, touch) {
  const rect = canvas.getBoundingClientRect()
  const scaleX = canvas.width / rect.width
  const scaleY = canvas.height / rect.height
  return {
    x: Math.round((touch.clientX - rect.left) * scaleX),
    y: Math.round((touch.clientY - rect.top) * scaleY)
  }
}
