const POINT_RADIUS = 4
const STROKE_COLOR = "#3b82f6"


export function drawPoint(ctx, x, y) {
  if (!ctx) return
  const px = Number(x)
  const py = Number(y)
  ctx.beginPath()
  ctx.arc(px, py, POINT_RADIUS, 0, 2 * Math.PI)
  ctx.fillStyle = STROKE_COLOR
  ctx.fill()
}

export function redrawAll(ctx, canvas, strokes, drawPointFn) {
  if (!ctx || !canvas) return
  ctx.clearRect(0, 0, canvas.width, canvas.height)
  for (const stroke of strokes) {
    for (const p of stroke) {
      drawPointFn(p.x, p.y)
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
