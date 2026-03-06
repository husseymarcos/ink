import * as canvasUtil from "./canvas.js"

export function setupPointerListeners(canvas, hook) {
  canvas.addEventListener("mousedown", (e) => onDown(e, hook, canvas))
  canvas.addEventListener("mousemove", (e) => onMove(e, hook, canvas))
  canvas.addEventListener("mouseup", () => onUp(hook))
  canvas.addEventListener("mouseleave", () => onUp(hook))
}

const CURSOR_THROTTLE_MS = 40
let lastCursorSentAt = 0

function onDown(e, hook, canvas) {
  hook.drawing = true
  const { x, y } = canvasUtil.getCoords(canvas, e)
  hook._sendPoint(x, y, true)
  maybeSendCursor(x, y, hook)
}

function onMove(e, hook, canvas) {
  const { x, y } = canvasUtil.getCoords(canvas, e)
  if (hook.drawing) {
    hook._sendPoint(x, y, false)
  }
  maybeSendCursor(x, y, hook)
}

function onUp(hook) {
  hook.drawing = false
}

function maybeSendCursor(x, y, hook) {
  const now = performance.now()
  if (now - lastCursorSentAt < CURSOR_THROTTLE_MS) return
  lastCursorSentAt = now
  if (typeof hook._sendCursor === "function") {
    hook._sendCursor(x, y)
  }
}
