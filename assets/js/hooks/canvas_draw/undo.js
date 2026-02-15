export function setupUndoButton(el, onUndo) {
  const btn = el?.closest("[data-canvas-container]")?.querySelector("[data-canvas-undo]")
  if (!btn) return null
  btn.addEventListener("click", (e) => {
    e.preventDefault()
    onUndo()
  })
  return btn
}

export function setupKeyboard(handleKeydown) {
  document.addEventListener("keydown", handleKeydown)
}

export function updateUndoButton(button, strokesLength) {
  if (button) {
    button.disabled = strokesLength === 0
  }
}
