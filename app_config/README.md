# LGKA+ Centralized App Configuration

## Overview
This centralized configuration system allows you to manage all app metadata (name, version, icons, package identifiers) from a single location instead of editing multiple platform-specific files.

## Quick Start

### 1. Edit Configuration
Edit `app_config/app_config.yaml` with your desired settings:

```yaml
# App Identity
app_name: "LGKA+"
app_description: "LGKA+ App - Digitaler Vertretungsplan"
package_name: "com.lgka"

# Version Configuration
version_name: "1.6.0"
version_code: "19"

# App Icon Configuration
app_icon_path: "assets/images/app-icons/app-logo.png"
```

### 2. Apply Configuration
Run the update script:
```bash
./scripts/update_app_config.sh
```

That's it! The script will automatically update all platform-specific files and regenerate app icons.

## What Gets Updated

### ✅ Cross-Platform
- **App Name**: Displayed on home screen and app switcher
- **App Version**: Version name and build number
- **App Icon**: Generated for all required sizes on both platforms
- **Package/Bundle Identifier**: Consistent across platforms

### 🤖 Android Specific
- `android/app/build.gradle.kts` - applicationId, namespace
- `android/app/src/main/AndroidManifest.xml` - app label
- All app icon sizes in `android/app/src/main/res/mipmap-*`

### 🍎 iOS Specific  
- `ios/Runner/app_config.xcconfig` - display name
- `ios/Runner/Info.plist` - uses variables from xcconfig
- All app icon sizes in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### 📦 Flutter
- `pubspec.yaml` - version, description, launcher icons config

## Configuration Options

### Required Fields
- `app_name`: Display name shown to users
- `version_name`: Semantic version (e.g., "1.6.0")  
- `version_code`: Build number (incremental integer)
- `app_icon_path`: Path to source icon image

### Optional Fields
- `app_description`: App description
- `package_name`: Bundle/package identifier
- `development_team`: iOS development team ID

## Changing App Icon

1. Replace the image file at the path specified in `app_icon_path`
2. Run `./scripts/update_app_config.sh`
3. The script will automatically generate all required icon sizes

**Icon Requirements:**
- Format: PNG
- Recommended size: 1024x1024px or larger
- Square aspect ratio
- No transparency (will be removed on iOS)

## Version Management

Update version by editing the config file:
```yaml
version_name: "1.7.0"  # Semantic version for users
version_code: "20"     # Build number (must increment)
```

The script applies this to:
- `pubspec.yaml` as `version: 1.7.0+20`
- Android `versionName` and `versionCode`
- iOS `CFBundleShortVersionString` and `CFBundleVersion`

## Manual Updates

If you need to make changes manually:

1. **Dart script only**: `dart run scripts/apply_app_config.dart`
2. **Icons only**: `dart run flutter_launcher_icons`
3. **Dependencies**: `flutter pub get`

## Troubleshooting

### Common Issues

**"❌ Error: app_config/app_config.yaml not found"**
- Ensure you're in the project root directory
- Check that the config file exists

**"Package yaml not found"**
- Run `flutter pub get` first

**Icons not updating**
- Ensure the icon file exists at the specified path
- Check file permissions
- Try `flutter clean` before rebuilding

### Verifying Changes

After running the script, verify updates:

```bash
# Check version in pubspec.yaml
grep "version:" pubspec.yaml

# Check Android app name
grep "android:label" android/app/src/main/AndroidManifest.xml

# Check iOS app name  
cat ios/Runner/app_config.xcconfig
```

## Development Workflow

1. **Making Changes**:
   - Edit `app_config/app_config.yaml`
   - Run `./scripts/update_app_config.sh`
   - Clean and rebuild: `flutter clean && flutter build <platform>`

2. **Version Bumps**:
   - Increment `version_code` for any release
   - Update `version_name` for feature releases
   - Run the update script

3. **New Icons**:
   - Replace the source icon file
   - Run the update script
   - Icons are automatically generated for all sizes

This system ensures consistency across platforms and eliminates the need to manually edit multiple configuration files. 