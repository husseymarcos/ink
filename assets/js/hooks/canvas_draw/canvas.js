const POINT_RADIUS = 4

export function drawPoint(ctx, x, y, color) {
  if (!ctx) return
  const px = Number(x)
  const py = Number(y)
  ctx.beginPath()
  ctx.arc(px, py, POINT_RADIUS, 0, 2 * Math.PI)
  ctx.fillStyle = color
  ctx.fill()
}

export function redrawAll(ctx, canvas, strokes, drawPointFn, defaultColor) {
  if (!ctx || !canvas) return
  ctx.clearRect(0, 0, canvas.width, canvas.height)
  for (const stroke of strokes) {
    const points = stroke.points || stroke
    const color = stroke.color || defaultColor
    for (const p of points) {
      drawPointFn(p.x, p.y, color)
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
