import * as canvasUtil from "./canvas.js"

export function setupPointerListeners(canvas, hook) {
  canvas.addEventListener("mousedown", (e) => onDown(e, hook, canvas))
  canvas.addEventListener("mousemove", (e) => onMove(e, hook, canvas))
  canvas.addEventListener("mouseup", () => onUp(hook))
  canvas.addEventListener("mouseleave", () => onUp(hook))

  canvas.addEventListener(
    "touchstart",
    (e) => {
      if (e.touches.length !== 1) return
      e.preventDefault()
      const { x, y } = canvasUtil.getCoordsFromTouch(canvas, e.touches[0])
      onDownTouch({ x, y }, hook, canvas)
    },
    { passive: false }
  )
  canvas.addEventListener(
    "touchmove",
    (e) => {
      if (e.touches.length !== 1) return
      e.preventDefault()
      const { x, y } = canvasUtil.getCoordsFromTouch(canvas, e.touches[0])
      onMoveTouch({ x, y }, hook, canvas)
    },
    { passive: false }
  )
  canvas.addEventListener(
    "touchend",
    (e) => {
      if (e.changedTouches.length !== 1) return
      e.preventDefault()
      onUp(hook)
    },
    { passive: false }
  )
  canvas.addEventListener(
    "touchcancel",
    (e) => {
      e.preventDefault()
      onUp(hook)
    },
    { passive: false }
  )
}

const CURSOR_THROTTLE_MS = 40
let lastCursorSentAt = 0

function onDown(e, hook, canvas) {
  const { x, y } = canvasUtil.getCoords(canvas, e)
  handleDown(x, y, hook, canvas)
}

function onDownTouch({ x, y }, hook, canvas) {
  handleDown(x, y, hook, canvas)
}

function handleDown(x, y, hook, _canvas) {
  hook.drawing = true
  hook._sendPoint(x, y, true)
  maybeSendCursor(x, y, hook)
}

function onMove(e, hook, canvas) {
  const { x, y } = canvasUtil.getCoords(canvas, e)
  handleMove(x, y, hook)
}

function onMoveTouch({ x, y }, hook, _canvas) {
  handleMove(x, y, hook)
}

function handleMove(x, y, hook) {
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
