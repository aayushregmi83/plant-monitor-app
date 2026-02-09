@echo off
REM Plant Monitor Flutter APK Build Script
REM This script automates the build process with error handling

echo ============================================================================
echo Plant Monitor - Flutter APK Builder
echo ============================================================================
echo.

REM Navigate to project directory
cd /d "%~dp0"

if not exist "pubspec.yaml" (
    echo ERROR: pubspec.yaml not found. Make sure you run this script from the project root.
    echo Expected location: plant_monitor\ folder
    pause
    exit /b 1
)

echo [1] Checking Flutter installation...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found in PATH. Please install Flutter SDK.
    echo Download: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo [2] Running flutter clean...
call flutter clean

echo [3] Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies.
    pause
    exit /b 1
)

echo [4] Building release APK...
echo This may take 5-10 minutes on first build. Please be patient...
echo.

call flutter build apk --release

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed. Possible causes:
    echo   1. Network issue downloading Gradle/dependencies
    echo   2. Insufficient disk space
    echo   3. Java version incompatibility
    echo.
    echo Solutions:
    echo   - Check your internet connection
    echo   - Free up disk space (need ~2GB free)
    echo   - Make sure Java is in PATH
    echo   - Run: flutter doctor -v
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================================
echo BUILD SUCCESSFUL!
echo ============================================================================
echo.
echo APK Location:
echo   build\app\outputs\flutter-apk\app-release.apk
echo.
echo Next steps:
echo   1. Connect your Android phone via USB
echo   2. Enable USB Debugging on phone
echo   3. Run: adb install -r build\app\outputs\flutter-apk\app-release.apk
echo Or manually transfer the APK file to your phone and install.
echo.
echo ============================================================================
pause
