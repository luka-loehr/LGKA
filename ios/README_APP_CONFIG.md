# iOS App Configuration

## Overview
The iOS app is now configured to automatically use centralized configuration values, similar to how Android works.

## App Display Name
To change the app display name that appears on the iOS home screen:

1. Edit `ios/Runner/app_config.xcconfig`
2. Change the `APP_DISPLAY_NAME` value
3. Rebuild the app

Example:
```
APP_DISPLAY_NAME = LGKA+
```

## Version Information
Version and build numbers are automatically pulled from `pubspec.yaml`:
- `CFBundleShortVersionString` uses `$(FLUTTER_BUILD_NAME)` from pubspec.yaml version
- `CFBundleVersion` uses `$(FLUTTER_BUILD_NUMBER)` from pubspec.yaml version

## Bundle Identifier
The bundle identifier is set to `com.lgka` to match the Android version.

## How It Works
- `app_config.xcconfig` defines the app display name
- This file is included in `Debug.xcconfig` and `Release.xcconfig`
- `Info.plist` references `$(APP_DISPLAY_NAME)` which gets the value from the xcconfig
- Version info is automatically synced with `pubspec.yaml`

This ensures consistency between iOS and Android platforms and makes updates easier. 