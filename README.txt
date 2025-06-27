# LGKA Flutter Cleaning Scripts

These scripts perform deep cleaning of the LGKA Flutter project while preserving all essential files.

## Location
This directory is located at: /Users/Luka/Documents/LGKA+/main/lgka_flutter_cleaning_scripts/

## Available Scripts
- clean_deep_mac.sh - For Mac/Linux systems

## How to Use

1. Copy the appropriate script to your Flutter project root directory
2. Make it executable (Mac/Linux): chmod +x clean_deep_mac.sh
3. Run the script: ./clean_deep_mac.sh

## What Gets Cleaned
- iOS: Pods, symlinks, ephemeral files, user data, lock files
- macOS: Ephemeral files, generated configs
- Android: .gradle cache, build dirs, .kotlin sessions, local.properties, generated files
- Flutter: .dart_tool, pubspec.lock, plugin dependencies, .metadata, .packages
- IDE: .idea directory, all .iml files
- OS Files: .DS_Store, Thumbs.db, swap files, temp files
- Build directories and backup files

## What Gets Preserved
- All source code (lib/, assets/, etc.)
- Configuration files (pubspec.yaml, app_config/, etc.)
- Platform configs (AndroidManifest.xml, Info.plist, etc.)
- Keystore files (keystore/key.jks, key.properties)
- Documentation files

## After Cleaning
Run these commands to restore the project:
1. flutter pub get
2. cd ios && pod install && cd .. (for iOS development)
3. flutter run (to test)

The scripts will show the final project size after cleaning. 