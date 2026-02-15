import { Socket } from "phoenix"

export const CanvasDraw = {
  mounted() {
    this.canvas = this.el
    this.ctx = this.canvas.getContext("2d")
    this.drawing = false

    const roomId = this.el.dataset.roomId
    if (!roomId) return

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
    const socket = new Socket("/socket", { params: { _csrf_token: csrfToken } })
    socket.connect()

    const channel = socket.channel(`canvas:room:${roomId}`, {})
    channel.join()
      .receive("ok", (resp) => {
        const points = (resp && resp.points) ? resp.points : []
        if (Array.isArray(points)) {
          for (const p of points) {
            this.drawPoint(p.x, p.y)
          }
        }
      })
      .receive("error", (resp) => console.error("Canvas channel join failed", resp))

    channel.on("draw_point", ({ x, y }) => {
      this.drawPoint(x, y)
    })

    const getCoords = (e) => {
      const rect = this.canvas.getBoundingClientRect()
      const scaleX = this.canvas.width / rect.width
      const scaleY = this.canvas.height / rect.height
      return {
        x: Math.round((e.clientX - rect.left) * scaleX),
        y: Math.round((e.clientY - rect.top) * scaleY)
      }
    }

    const sendAndDraw = (x, y) => {
      this.drawPoint(x, y)
      channel.push("draw", { x, y })
    }

    this.canvas.addEventListener("mousedown", (e) => {
      this.drawing = true
      const { x, y } = getCoords(e)
      sendAndDraw(x, y)
    })

    this.canvas.addEventListener("mousemove", (e) => {
      if (!this.drawing) return
      const { x, y } = getCoords(e)
      sendAndDraw(x, y)
    })

    this.canvas.addEventListener("mouseup", () => {
      this.drawing = false
    })
    this.canvas.addEventListener("mouseleave", () => {
      this.drawing = false
    })
  },

  drawPoint(x, y) {
    if (!this.ctx) return
    const r = Number(x)
    const s = Number(y)
    this.ctx.beginPath()
    this.ctx.arc(r, s, 4, 0, 2 * Math.PI)
    this.ctx.fillStyle = "#3b82f6"
    this.ctx.fill()
  }
}
