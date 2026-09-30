# 🔐 Flutter SHA-512 REST API Authentication Demo

A full-stack mobile and web authentication system demonstrating client-side **SHA-512 cryptographic hashing** integrated with a **Node.js + Express + SQLite** backend and a futuristic **Spline 3D-inspired glassmorphic UI**.

The backend is deployed live on **Render**, and the Flutter client supports running locally (Android Emulator, iOS, Web, Desktop) or against cloud deployments using build-time environment flags.

---

## 🏗️ Architecture

```text
NIC/
├── server/                               # Node.js + Express REST API
│   ├── index.js                          # Express endpoints, timingSafeEqual auth & SQLite setup
│   ├── users.db                          # SQLite DB (users table: id TEXT PRIMARY KEY, pwd_hash TEXT)
│   └── package.json                      # better-sqlite3, express, cors, engines: node >=18
│
├── crypto_sha512_demo/                   # Flutter Client Application
│   ├── lib/
│   │   ├── main.dart                     # Material 3 theme & navigation routes
│   │   ├── api_service.dart              # SHA-512 hasher, 60s timeout, and dynamic URL resolution
│   │   ├── login_page.dart               # 3D avatar, glassmorphic card, cold-start reactive state
│   │   └── home_page.dart                # Authenticated dashboard & SHA-512 hash inspector
│   ├── android/                          # Configured with INTERNET permission and cleartext traffic
│   └── pubspec.yaml                      # Dependencies: crypto, http, cupertino_icons
│
├── .gitignore                            # Excludes node_modules, users.db, *.apk, build artifacts
└── README.md                             # Project documentation
```

### Core Architecture Highlights:
- **Client-Side SHA-512 Hashing**: Passwords are converted directly on the client to a 128-character hexadecimal digest via `package:crypto` before transmission over the network. Plaintext passwords never leave the device.
- **Constant-Time Verification**: The backend compares client hashes with stored values using `crypto.timingSafeEqual` in Node.js to mitigate timing side-channel attacks.
- **Flexible API URL Resolution**: `ApiService.baseUrl` dynamically determines the target endpoint:
  1. Build-time `--dart-define=API_BASE_URL=...` (highest precedence, used for cloud deployments like Render).
  2. Android Emulator fallback: `http://10.0.2.2:3000` (maps to host loopback).
  3. Web / Desktop / iOS Simulator fallback: `http://localhost:3000`.
- **Live Cloud Deployment**: Backend is hosted on Render at:
  ```text
  https://nic-lcym.onrender.com
  ```

---

## 📡 REST API Endpoints

### 1. `GET /health`
Verifies server health and connectivity (used for wake-up pings and monitoring).
- **Response (200 OK)**:
  ```json
  {
    "ok": true
  }
  ```

### 2. `POST /api/login`
Validates credentials using timing-safe SHA-512 verification.
- **Request Headers**: `Content-Type: application/json`
- **Request Body**:
  ```json
  {
    "id": "alex_dev",
    "pwdHash": "bed4efa1d4fdbd954bd3705d6a2a78270ec9a52ecfbfb010c61862af5c76af1761ffeb1aef6aca1bf5d02b3781aa854fabd2b69c790de74e17ecfec3cb6ac4bf"
  }
  ```
- **Validation**: Ensures `id` is present and `pwdHash` is exactly 128 hexadecimal characters (`/^[0-9a-f]{128}$/i`).
- **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "id": "alex_dev",
    "hash": "bed4efa1d4fdbd954bd3705d6a2a78270ec9a52ecfbfb010c61862af5c76af1761ffeb1aef6aca1bf5d02b3781aa854fabd2b69c790de74e17ecfec3cb6ac4bf"
  }
  ```
- **Error Response (401 Unauthorized)**:
  ```json
  {
    "success": false,
    "message": "Invalid id or password"
  }
  ```

### 3. `POST /api/register` *(Optional)*
Registers a new user account with an initial 128-hex SHA-512 hash.
- **Request Body**: `{ "id": "new_user", "pwdHash": "<128-hex-string>" }`
- **Success Response (201 Created)**: `{ "success": true, "id": "new_user", "hash": "..." }`
- **Conflict Response (409 Conflict)**: `{ "success": false, "message": "User already exists" }`

---

## 🔑 Demo Credentials

The SQLite database seeds two preconfigured accounts upon startup:

| ID / Username | Plaintext Password | SHA-512 Hex Hash (128 chars) |
| :--- | :--- | :--- |
| `alex_dev` | `password123` | `bed4efa1d4fdbd954bd3705d6a2a78270ec9a52ecfbfb010c61862af5c76af1761ffeb1aef6aca1bf5d02b3781aa854fabd2b69c790de74e17ecfec3cb6ac4bf` |
| `navaneet` | `test1234` | `2bbe0c48b91a7d1b8a6753a8b9cbe1db16b84379f3f91fe115621284df7a48f1cd71e9beb90ea614c7bd924250aa9e446a866725e685a65df5d139a5cd180dc9` |

---

## 🚀 How to Run the Server Locally

### 1. Install & Start
```bash
cd server
npm install
npm start
```
The server will bind to `0.0.0.0:3000` by default.

### 2. Environment Variables
- `PORT`: Port to listen on (defaults to `3000` or `process.env.PORT` on Render).
- `DB_PATH`: SQLite database file path (defaults to `./users.db`).

---

## 📱 How to Run the Flutter App on an Emulator

### 1. Prerequisites
- Flutter SDK installed and on your `PATH`.
- Android emulator running (e.g. `emulator-5554`).
- Java 21+ configured.

### 2. Run against Local Server
Make sure the local server is running on port 3000, then:
```bash
cd crypto_sha512_demo
flutter pub get
flutter run -d emulator-5554
```
*(The app automatically points to `http://10.0.2.2:3000` on Android emulators to communicate with the host).*

### 3. Run against Render Production API
```bash
cd crypto_sha512_demo
flutter run -d emulator-5554 --dart-define=API_BASE_URL=https://nic-lcym.onrender.com
```

---

## 📦 How to Build the Release APK

To create a self-contained release APK configured with the production cloud backend:

```bash
cd crypto_sha512_demo
flutter build apk --release --dart-define=API_BASE_URL=https://nic-lcym.onrender.com
```

The APK will be generated at:
```text
crypto_sha512_demo/build/app/outputs/flutter-apk/app-release.apk
```

### Install onto an Emulator or Physical Device
```bash
adb install -r crypto_sha512_demo/build/app/outputs/flutter-apk/app-release.apk
```

---

## ⚠️ Free-Tier Cold-Start Note

> [!NOTE]
> **Render Free Tier Spin-Down**:
> Services hosted on Render's free tier automatically spin down (sleep) after 15 minutes of inactivity. When a new HTTP request arrives:
> 1. The first cold-start request can take **~45–55 seconds** while the container provisions and executes `npm start`.
> 2. Subsequent requests respond instantaneously (~100–300ms).
>
> **Client Accommodations in Flutter**:
> - **Extended Timeout**: The HTTP client timeout in `ApiService.login` is set to **60 seconds** (instead of standard 5–10s) to prevent premature aborts during a cold spin-up.
> - **Reactive UI Feedback**: If the authentication request takes longer than **5 seconds**, the login button UI automatically updates its label to:
>   ```text
>   ⏳ Waking up server…
>   ```
>   giving the user clear visual feedback while Render provisions the container.
