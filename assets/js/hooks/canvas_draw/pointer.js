export function setupPointerListeners(canvas, hook) {
  canvas.addEventListener("mousedown", (e) => onDown(e, hook))
  canvas.addEventListener("mousemove", (e) => onMove(e, hook))
  canvas.addEventListener("mouseup", () => onUp(hook))
  canvas.addEventListener("mouseleave", () => onUp(hook))
}

function onDown(e, hook) {
  hook.drawing = true
  const { x, y } = hook._getCoords(e)
  hook._sendPoint(x, y, true)
}

function onMove(e, hook) {
  if (!hook.drawing) return
  const { x, y } = hook._getCoords(e)
  hook._sendPoint(x, y, false)
}

function onUp(hook) {
  hook.drawing = false
}
