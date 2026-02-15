import { Socket } from "phoenix"

export function connectChannel(roomId) {
  const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
  const socket = new Socket("/socket", { params: { _csrf_token: csrfToken } })
  socket.connect()
  return socket.channel(`canvas:room:${roomId}`, {})
}

export function setupChannelHandlers(channel, hook) {
  channel.join()
    .receive("ok", (resp) => hook._onJoinOk(resp))
    .receive("error", (resp) => console.error("Canvas channel join failed", resp))

  channel.on("draw_point", (payload) => hook._onDrawPoint(payload))
  channel.on("strokes_replaced", (payload) => hook._onStrokesReplaced(payload))
}
