@echo off
echo 🧹 Deep cleaning LGKA Flutter project (Windows)...
echo.

:: Remove ALL iOS build and derived data
echo 📱 Deep cleaning iOS...
rmdir /s /q ios\Pods 2>nul
rmdir /s /q ios\.symlinks 2>nul
rmdir /s /q ios\Flutter\ephemeral 2>nul
del /f /q ios\Flutter\Flutter-Generated.xcconfig 2>nul
del /f /q ios\Flutter\flutter_export_environment.sh 2>nul
del /f /q ios\Flutter\Generated.xcconfig 2>nul
rmdir /s /q ios\Runner.xcworkspace\xcuserdata 2>nul
rmdir /s /q ios\Runner.xcodeproj\project.xcworkspace\xcuserdata 2>nul
del /f /q ios\Podfile.lock 2>nul
del /f /q ios\Flutter\.last_build_id 2>nul
echo ✅ iOS deep cleaned

:: Remove macOS build artifacts
echo 🖥️  Deep cleaning macOS...
rmdir /s /q macos\Flutter\ephemeral 2>nul
del /f /q macos\Flutter\Flutter-Generated.xcconfig 2>nul
del /f /q macos\Flutter\flutter_export_environment.sh 2>nul
del /f /q macos\Podfile.lock 2>nul
echo ✅ macOS deep cleaned

:: Remove ALL Android build artifacts and generated files
echo 🤖 Deep cleaning Android...
rmdir /s /q android\.gradle 2>nul
rmdir /s /q android\app\build 2>nul
rmdir /s /q android\build 2>nul
rmdir /s /q android\.kotlin 2>nul
del /f /q android\local.properties 2>nul
del /f /q android\app\src\main\java\io\flutter\plugins\GeneratedPluginRegistrant.java 2>nul
del /f /q android\*.iml 2>nul
del /f /q android\app\*.iml 2>nul
echo ✅ Android deep cleaned

:: Remove ALL Flutter generated files
echo 🦋 Deep cleaning Flutter files...
del /f /q .flutter-plugins-dependencies 2>nul
del /f /q .flutter-plugins 2>nul
rmdir /s /q .dart_tool 2>nul
del /f /q .packages 2>nul
del /f /q .metadata 2>nul
del /f /q pubspec.lock 2>nul
rmdir /s /q .idea 2>nul
del /f /q *.iml 2>nul
echo ✅ Flutter files deep cleaned

:: Remove OS-specific files
echo 🗑️  Removing OS-specific files...
del /s /f /q .DS_Store 2>nul
del /s /f /q Thumbs.db 2>nul
del /s /f /q *.swp 2>nul
del /s /f /q *.swo 2>nul
del /s /f /q *~ 2>nul
echo ✅ OS files cleaned

:: Remove any log files
echo 📝 Removing log files...
del /s /f /q *.log 2>nul
del /s /f /q *.tmp 2>nul
echo ✅ Log files cleaned

:: Remove build directory if exists
if exist build (
    echo 🏗️  Removing build directory...
    rmdir /s /q build
    echo ✅ Build directory cleaned
)

:: Remove any backup files
echo 💾 Removing backup files...
del /s /f /q *.bak 2>nul
del /s /f /q *.backup 2>nul
echo ✅ Backup files cleaned

echo.
echo ✨ Deep cleaning completed!
echo 📦 Only essential source code and config files remain.
echo.
echo 📊 To see final project size, run: dir /s
pause 