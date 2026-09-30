# 🔐 Flutter SHA-512 REST API Authentication Demo

A complete full-stack demonstration of client-side **SHA-512 cryptographic hashing** integrated with a **Node.js + Express + SQLite** backend and a futuristic **Spline 3D-inspired glassmorphic UI**, running seamlessly on Android emulators, web, and desktop.

---

## ⚡ Quick Run Steps

### 1. Start the Backend Server
```bash
cd ../server # or cd server from root
npm install
npm start
```
*The server initializes `users.db` in SQLite, seeds demo users, and listens on `http://0.0.0.0:3000`.*

### 2. Launch Android Emulator & Run Flutter App
```bash
# Ensure Java 21+ and Flutter are in your PATH
export JAVA_HOME="/opt/homebrew/Cellar/openjdk@21/21.0.9/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:/Users/navaneet.s/flutter/bin:$PATH"

cd crypto_sha512_demo
flutter pub get
flutter run -d emulator-5554 # or: flutter run -d chrome
```

---

## 🔑 Demo Credentials

| ID / Username | Password | Stored SHA-512 Hash |
| :--- | :--- | :--- |
| `alex_dev` | `password123` | `bed4efa1d4fdbd954bd3705d6a2a78270ec9a52ecfbfb010c61862af5c76af1761ffeb1aef6aca1bf5d02b3781aa854fabd2b69c790de74e17ecfec3cb6ac4bf` |
| `navaneet` | `test1234` | `2bbe0c48b91a7d1b8a6753a8b9cbe1db16b84379f3f91fe115621284df7a48f1cd71e9beb90ea614c7bd924250aa9e446a866725e685a65df5d139a5cd180dc9` |

---

## 🏗️ Architecture & Features

```text
NIC/
├── server/
│   ├── index.js              # Express REST API (timingSafeEqual verification)
│   ├── users.db              # SQLite database (table: users(id, pwd_hash))
│   └── package.json          # better-sqlite3, express, cors
│
└── crypto_sha512_demo/
    ├── lib/
    │   ├── main.dart         # Material 3 entry point & named routing
    │   ├── api_service.dart  # SHA-512 hasher & HTTP client (10.0.2.2 on Android)
    │   ├── login_page.dart   # Spline 3D glassmorphic login UI with live API auth
    │   └── home_page.dart    # Authenticated dashboard & hash inspector
    ├── android/              # Configured with INTERNET and usesCleartextTraffic
    └── pubspec.yaml          # Dependencies: crypto, http, cupertino_icons
```

### Key Highlights:
- **Client-Side SHA-512**: Passwords are converted to a 128-character hex digest using `package:crypto` before transmission.
- **Constant-Time Verification**: Backend uses `crypto.timingSafeEqual` in Node.js to prevent timing side-channel attacks.
- **Automatic IP Detection**: `ApiService` automatically uses `http://10.0.2.2:3000` when executing on Android emulators and `http://localhost:3000` on web/desktop.
- **Robust Error Handling**: Real-time feedback snackbars for invalid credentials, timeouts (8s), and network issues.

---

## 📡 REST API Endpoints

### 1. `POST /api/login`
- **Request Body**:
  ```json
  {
    "id": "alex_dev",
    "pwdHash": "bed4efa1d4fdbd954bd3705d6a2a78270ec9a52ecfbfb010c61862af5c76af1761ffeb1aef6aca1bf5d02b3781aa854fabd2b69c790de74e17ecfec3cb6ac4bf"
  }
  ```
- **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "id": "alex_dev",
    "hash": "bed4efa1..."
  }
  ```
- **Error Response (401 Unauthorized)**:
  ```json
  {
    "success": false,
    "message": "Invalid id or password"
  }
  ```

### 2. `POST /api/register` *(Optional)*
- Registers a new user with an initial 128-character SHA-512 hex hash.

---

## 🧪 Testing

```bash
cd crypto_sha512_demo
flutter test
```
*Runs all 7 unit and integration tests covering password hashing, UI components, and end-to-end API communication.*
