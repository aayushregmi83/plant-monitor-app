# Plant Monitor Flutter App

A complete, production-ready Flutter mobile app that mirrors your web-based Plant Monitor with:
- Real-time sensor dashboard (temperature, humidity, soil moisture)
- Live camera feed streaming from ESP32-CAM
- AI-powered fruit/vegetable detection from photos
- Plant disease analysis and diagnosis
- Smart home controls (fan, pump, bulb toggle with auto/manual modes)
- Persistent settings with configurable backend URL

## Quick Start (3 Steps)

### Step 1: Start Backend Server
```bash
cd ..
python server.py --port 5000
```

### Step 2: Build APK
Double-click `build_apk.bat` (automated) or run:
```bash
flutter pub get
flutter build apk --release
```

### Step 3: Install on Phone
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Then open Settings in app and set backend URL: `http://<your-pc-ip>:5000`

## Features

| Feature | Screen | Description |
|---------|--------|-------------|
| **Dashboard** | Home | Real-time sensor data, system status, device controls |
| **Image Detection** | Detect | Capture or upload image → get fruit/vegetable identification |
| **Disease Analysis** | Health Analysis | Upload leaf photo → get disease diagnosis & treatment info |
| **Live Camera** | Camera Feed | Stream video from ESP32-CAM connected to server |
| **Smart Controls** | Dashboard | Toggle fan/pump/bulb with auto/manual modes |
| **Settings** | Settings | Configure backend URL, persisted with SharedPreferences |

## Architecture

- **Frontend**: Flutter 3.38+ (cross-platform mobile)
- **Backend API**: Flask Python server (from parent folder `server.py`)
- **Storage**: SharedPreferences (local device storage)
- **HTTP Client**: http package for REST calls
- **Image Handling**: image_picker (camera/gallery), base64 encoding

## Project Structure
```
lib/
├── main.dart
├── screens/                          # UI screens
│   ├── dashboard_screen.dart         # Main dashboard
│   ├── home_screen.dart              # Image detection
│   ├── camera_feed.dart              # Live stream
│   ├── health_analysis_screen.dart   # Disease detection
│   └── settings_screen.dart          # Backend config
├── services/                         # API & data
│   ├── api_service.dart              # Detection API
│   ├── sensor_service.dart           # Sensors & commands
│   └── settings_service.dart         # Persistent storage
└── widgets/                          # Reusable components
    ├── stat_card.dart
    ├── detection_card.dart
    └── control_card.dart
```

## Requirements

- Flutter 3.38+ (2.1GB+)
- Dart 3.10+
- Android SDK API 21+ (Android 5.0)
- Java JDK 11+
- ~2GB free disk space (for build artifacts)
- Phone & PC on same Wi‑Fi network

## Building & Deployment

### Manual Build (from project root)
```bash
flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

### Installed via APK
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### For Google Play Store
See `DEPLOYMENT.md` section "For Production / Distribution"

## Configuration

Backend URL is stored locally on device (shared_preferences).

**Change URL anytime**:
1. Open app Settings (drawer → Settings)
2. Enter new backend URL (e.g., `http://192.168.1.42:5000`)
3. Tap Save

## Troubleshooting

| Issue | Solution |
|-------|----------|
| App won't connect to backend | Check backend running (`python server.py`), firewall allows port 5000, PC IP is correct, phone on same Wi‑Fi |
| "No data" on dashboard | Verify Settings has correct backend URL, server is still running |
| Build hangs downloading Gradle | Use better internet connection, or increase timeout in `android/gradle.properties` |
| Camera feed shows "No frame" | ESP32-CAM must be connected to server WebSocket |

## Full Documentation

See `DEPLOYMENT.md` for:
- Detailed setup instructions
- API endpoint reference
- Advanced troubleshooting
- Production build & signing
- Gradle properties tuning

## Support

- **Flutter Docs**: https://flutter.dev/docs
- **Server Code**: See parent `server.py` (Flask + PyTorch)
- **Issues**: Verify backend running, correct URL in Settings, firewall

---
**Plant Monitor v1.0** | Built with Flutter 3.38+ | Feb 2026
