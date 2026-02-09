# Plant Monitor Flutter App - Complete Deployment Guide

## Project Overview
Complete Flutter mobile app that mirrors your web-based Plant Monitor dashboard, with:
- **Dashboard**: Real-time sensor data (temperature, humidity, soil moisture)
- **Camera Feed**: Live streaming from ESP32-CAM
- **Health Analysis**: Plant disease detection via `/api/detect-disease`
- **Fruit Detection**: Image capture & fruit/vegetable detection
- **Smart Controls**: Fan, Pump, Bulb on/off toggles with auto/manual modes
- **Settings**: Configurable backend URL with persistent storage

## Project Structure
```
plant_monitor/
├── lib/
│   ├── main.dart                 # App entry point with routing
│   ├── screens/
│   │   ├── dashboard_screen.dart # Main dashboard with stats
│   │   ├── home_screen.dart      # Image detection screen
│   │   ├── camera_feed.dart      # Live camera stream
│   │   ├── health_analysis_screen.dart  # Disease detection
│   │   └── settings_screen.dart  # Backend URL config
│   ├── services/
│   │   ├── api_service.dart      # Image detection API calls
│   │   ├── sensor_service.dart   # Sensor data & commands
│   │   └── settings_service.dart # Persistent storage
│   └── widgets/
│       ├── stat_card.dart        # Dashboard stat display
│       ├── detection_card.dart   # Detection result display
│       └── control_card.dart     # Fan/Pump/Bulb controls
├── pubspec.yaml     # Dependencies (http, image_picker, shared_preferences)
├── android/         # Android-specific configuration
└── ios/             # iOS-specific configuration (optional)
```

## Prerequisites
- Flutter SDK 3.38+ : https://flutter.dev/docs/get-started/install
- Android Studio or cmdline-tools for Android SDK
- Physical Android device (or emulator) with:
  - Developer Options enabled
  - USB Debugging enabled (for physical device)
- PC and phone on same Wi‑Fi network

## Backend Setup (Before Running App)

### Step 1: Start the Python server
From the parent folder (`E:\Desktop\Pytorch\.venv\greenhouse\finally\12`):

```bash
python server.py --port 5000
```

**Expected output**:
```
[OK] Server starting on port 5000...
Server starting on port 5000... Press Ctrl+C to stop
```

### Step 2: Find your PC LAN IP (Windows)
Open PowerShell and run:
```powershell
ipconfig
```
Look for **IPv4 Address** under your Wi‑Fi adapter (e.g., `192.168.1.42`).

### Step 3: Allow firewall (if needed)
- Open Windows Defender Firewall → Allow an app through firewall
- Add `python.exe` and allow on Private network
- Or temporarily disable Windows Firewall for testing

### Step 4: Verify backend is reachable
From your phone browser, visit: `http://<your-pc-ip>:5000`
You should see the Plant Monitor dashboard.

## APK Build & Installation

### Option A: Build APK on Your PC (Recommended)

**Prerequisites**:
- Android cmdline-tools must be installed (Flutter doctor should show ✓)
- Gradle wrapper will download ~500MB the first time (requires good internet)

**Steps**:

1. **Navigate to project**:
```bash
cd "E:\Desktop\Pytorch\.venv\greenhouse\finally\12\plant_monitor"
```

2. **Get dependencies**:
```bash
flutter pub get
```

3. **Build release APK** (takes 3-10 min on first build):
```bash
flutter build apk --release
```

4. **Locate APK**:
```
E:\Desktop\Pytorch\.venv\greenhouse\finally\12\plant_monitor\build\app\outputs\flutter-apk\app-release.apk
```

5. **Install on phone via USB**:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Or manually transfer the APK file and install via your phone's file manager.

### Option B: Build APK if Network Issues Occur

If Gradle times out downloading dependencies:

1. **Use a VPN or better network connection**
2. **Clear Gradle cache** and retry:
```bash
Remove-Item -Path "C:\Users\$env:USERNAME\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
flutter build apk --release
```

3. **Alternatively, use direct connectivity**:
```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## First Run: Configure Backend URL

### Step 1: Connect phone to same Wi‑Fi as PC

### Step 2: Launch app on phone
- Tap app icon (should open Dashboard, but won't show data yet)

### Step 3: Open Settings  
- Tap hamburger menu (☰) → Settings

### Step 4: Set backend URL
- **Enter**: `http://<your-pc-ip>:5000`
  - Example: `http://192.168.1.42:5000`
- Tap **Save**

### Step 5: Verify connection
- Go back to Dashboard
- If sensor data appears, your connection is working!
- If not → check server is running, firewall allows it, IP is correct

## Usage Guide

### Dashboard (Home Screen)
- **Temperature, Humidity, Soil Moisture**: Live sensor data (updates every 3 sec)
- **ESP32 Info**: Server status, camera connection, detector availability
- **Controls**: Fan, Pump, Bulb toggles
  - **Manual switch**: Enable to override auto-control
  - **State switch**: Turn device on/off when in manual mode

### Detect (Image)
1. Tap **Detect (Image)** from dashboard or drawer
2. **Camera**: Take a photo of fruit/vegetable
3. **Gallery**: Pick existing photo
4. Tap **Detect**
5. View results: Label, confidence %, top predictions, fun facts

### Health Analysis
1. From drawer → **Health Analysis**
2. Pick/take photo of leaf or plant
3. Tap **Analyze**
4. View disease/health info: Name, severity, symptoms, treatment, prevention

### Live Feed
1. From drawer → **Live Feed** (or dashboard button)
2. Tap **Start** to begin polling camera frames
3. Tap **Stop** to stop
- Requires: ESP32-CAM connected to server WebSocket

## API Endpoints Used

The app calls these backend endpoints:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/detect` | POST | Fruit/vegetable detection |
| `/api/detect-disease` | POST | Plant disease detection |
| `/api/sensor-data` | GET | Fetch sensor readings |
| `/api/commands/<device_id>` | GET | Get control state |
| `/api/commands/<device_id>` | POST | Send control commands |
| `/api/camera-feed` | GET | Get latest camera frame |
| `/api/status` | GET | Get system status |

All requests use the backend URL configured in Settings.

## Troubleshooting

### "No frame available" in Camera Feed
**Cause**: ESP32-CAM not connected to server
**Fix**: Connect ESP32-CAM to server via WebSocket, confirm in server logs

### "Unable to detect" error
**Cause**: Model not trained, or image quality poor
**Fix**: 
- Ensure model file exists: `models/fruit_veg_model.pth`
- Train model: `python server.py --train` (requires dataset)
- Take clearer photo with good lighting

### Connection refused errors
**Cause**: Server not running or IP/firewall issue
**Steps**:
1. Confirm server running: `python server.py --port 5000`
2. Verify PC IP: `ipconfig`
3. Test from phone browser:  `http://<ip>:5000`
4. Check Windows firewall allows Python

### Backend URL not saving
**Cause**: SharedPreferences permission issue
**Fix**: 
- Reinstall app: Uninstall & reinstall APK
- Or clear app data: Phone Settings → Apps → Plant Monitor → Clear Data

## Development Notes

- **Framework**: Flutter 3.38+, Dart 3.10+
- **Min Android**: API 21+ (Android 5.0)
- **Architecture**: Cross-platform (iOS version requires minimal tweaks)
- **Build time**: ~3-10 min first build (downloads Gradle, dependencies), ~1-2 min subsequent builds

## Build Issues & Solutions

### "Gradle threw an error while downloading artifacts"
- **Cause**: Network timeout or unreliable connection
- **Solution**: 
  - Use a wired Ethernet connection or better Wi‑Fi
  - Increase gradle timeout: Edit `android/gradle.properties` (see below)
  - Retry build

### Android gradle.properties Fix (if timeouts persist)
Create/edit: `E:\Desktop\Pytorch\.venv\greenhouse\finally\12\plant_monitor\android\gradle.properties`

```properties
org.gradle.jvmargs=-Xmx4096m
org.gradle.parallel=true
org.gradle.daemon=true
org.gradle.configureondemand=true
android.useAndroidX=true
android.enableJetifier=true
```

Then retry:
```bash
flutter build apk --release
```

## For Production / Distribution

To build a signed APK for Google Play Store:

1. **Create keystore** (one-time):
```bash
keytool -genkey -v -keystore C:\Users\%USERNAME%\key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

2. **Create signing config**: Edit `android/key.properties`:
```properties
storeFile=C:\\Users\\<username>\\key.jks
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=key
```

3. **Build signed APK**:
```bash
flutter build apk --release
```

## Next Steps

1. ✅ **Backend server running?** - Start server (see "Backend Setup")
2. ✅ **APK built?** - Build APK (see "APK Build & Installation")
3. ✅ **App installed?** - Install APK on phone
4. ✅ **Backend URL configured?** - Enter URL in Settings (see "First Run")
5. ✅ **Testing** - Try Dashboard → Camera Feed → Detect screens
6. 🚀 **Deploy** - Customize, add features, build signed APK for store

## Support

- **Flutter Docs**: https://flutter.dev/docs
- **Android Docs**: https://developer.android.com
- **Backend**: Powered by Flask + PyTorch (see `server.py`)

---
**Generated**: Feb 9, 2026  
**Plant Monitor v1.0**
