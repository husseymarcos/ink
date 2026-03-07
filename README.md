# Ink

![Ink logo](priv/static/images/logo.png)

**Real-time collaborative whiteboard.** Draw, share, and work together on the same canvas.

---

## What is Ink?

Ink is a digital whiteboard built for teams. Create rooms, invite whoever you need, and everyone can draw at the same time on the same canvas. Strokes appear instantly on all devices—no refresh or manual sync.

---

## Features

| Feature | Description |
|---------|-------------|
| **Real-time drawing** | Draw with mouse or touch. Strokes render smoothly and continuously, even when you draw quickly. |
| **Multiple rooms** | Create as many rooms as you need (meetings, projects, brainstorming). Each room has its own canvas. |
| **Room preview** | The room list shows a thumbnail of each board so you can find the one you need. |
| **Live collaboration** | See who’s in the room and where each person’s cursor is in real time. |
| **Multiple colors** | Pick stroke color before drawing to organize ideas or highlight parts of the sketch. |
| **Undo** | Undo the last stretch of drawing with one click or keyboard shortcut (Ctrl/Cmd + Z). |
| **User accounts** | Sign up and log in to create rooms and access your boards. |

---

## Getting started

1. **Install dependencies and set up the database**

   ```bash
   mix deps.get
   mix ecto.setup
   ```

2. **Start the application**

   ```bash
   mix phx.server
   ```

3. **Open your browser** at [http://localhost:4000](http://localhost:4000).

4. Create an account, log in, and create your first room to start drawing.

---

## Requirements

- Elixir 1.14 or higher  
- PostgreSQL  
- Node.js (for front-end assets in development)

---

## Learn more

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
