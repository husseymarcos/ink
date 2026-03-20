export function bindPasswordRow(row) {
  if (row.dataset.passwordToggleBound === "true") return

  const input = row.querySelector("input[type=\"password\"], input[type=\"text\"]")
  const btn = row.querySelector("[data-password-toggle]")
  const showIcon = row.querySelector("[data-password-icon=\"show\"]")
  const hideIcon = row.querySelector("[data-password-icon=\"hide\"]")
  if (!input || !btn) return

  row.dataset.passwordToggleBound = "true"

  const setVisible = (visible) => {
    input.type = visible ? "text" : "password"
    btn.setAttribute("aria-pressed", visible ? "true" : "false")
    btn.setAttribute("aria-label", visible ? "Hide password" : "Show password")
    showIcon?.classList.toggle("hidden", visible)
    hideIcon?.classList.toggle("hidden", !visible)
  }

  const onClick = () => setVisible(input.type === "password")
  btn.addEventListener("click", onClick)

  return () => {
    btn.removeEventListener("click", onClick)
    delete row.dataset.passwordToggleBound
  }
}

export function initPasswordToggles() {
  document.querySelectorAll("[data-password-row]").forEach((row) => bindPasswordRow(row))
}

export const PasswordToggle = {
  mounted() {
    this._unbind = bindPasswordRow(this.el)
  },

  destroyed() {
    this._unbind?.()
  },
}
