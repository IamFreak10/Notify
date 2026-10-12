# 📱 Notify — Real-time Notification App for Bornomala

A lightweight Flutter mobile application & Go microservice built to receive instant live notifications whenever a customer places an order or any store event occurs in **Bornomala**.

Powered by [`github.com/IamFreak10/Gonotify`](https://github.com/IamFreak10/Gonotify).

---

## 🏗️ Architecture

```
[Bornomala Backend (Node.js/Express)]
              │
              │  HTTP POST /publish (Non-blocking, conditional)
              ▼
[Notify Server (Go on Render / Local)]
              │
              │  WebSocket with Heartbeat (Ping/Pong)
              ▼
[Notify Mobile App (Flutter on Android/iOS)]
```

---

## 🚀 Running the Mobile App (Flutter)

### 1. Requirements
- Flutter SDK (v3.0.0+)
- Android Device / Emulator

### 2. Run
```bash
# Get dependencies
flutter pub get

# Run on connected device
flutter run
```

### 3. Connect to Server
1. Open the Notify app on your phone.
2. Tap the **Settings icon** (⚙️) on the top right.
3. Enter your WebSocket URL:
   - For Render deployment: `wss://your-notify-app.onrender.com/ws`
   - For local Wi-Fi testing: `ws://192.168.0.x:8080/ws`
4. The status badge will turn 🟢 **Connected**.

---

## ☁️ Deploying Go Server to Render

The `server/` directory contains a zero-config Go server ready to be deployed to Render:

1. Create a **New Web Service** on [Render.com](https://render.com).
2. Connect this repository: `IamFreak10/Notify`.
3. Set **Root Directory** to `server`.
4. Runtime: **Docker** (or Go).
5. Deploy! Your server will provide:
   - `wss://<app-name>.onrender.com/ws` (WebSocket for Phone)
   - `https://<app-name>.onrender.com/publish` (HTTP Webhook for Bornomala)
   - `https://<app-name>.onrender.com/health` (Health Check for UptimeRobot)

---

## 📄 License

MIT License © 2026 [IamFreak10](https://github.com/IamFreak10)

---

## 👥 Contributors

- **[Mahfuj Abdulla (@IamFreak10)](https://github.com/IamFreak10)** — Lead Developer & Maintainer
- **Antigravity AI (Google DeepMind)** — Co-designer & Architecture Pair Programmer
