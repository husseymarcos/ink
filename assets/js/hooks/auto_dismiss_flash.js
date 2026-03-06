export const AutoDismissFlash = {
  mounted() {
    const timeoutAttr = this.el.dataset.timeout
    const timeoutMs = Number(timeoutAttr || "4500")

    this._timer = window.setTimeout(() => {
      this.el.dispatchEvent(
        new MouseEvent("click", {bubbles: true, cancelable: true, view: window})
      )
    }, Number.isFinite(timeoutMs) ? timeoutMs : 4500)
  },

  destroyed() {
    if (this._timer) window.clearTimeout(this._timer)
  },
}

