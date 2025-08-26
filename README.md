![LGKA+ Banner](app_store_assets/banners/lgka_banner_1024x500.png)

# LGKA+ – The app for Lessing-Gymnasium Karlsruhe

[![Flutter](https://img.shields.io/badge/Flutter-Latest-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=flat)](https://github.com/luka-loehr/LGKA/releases)
[![License](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-orange?style=flat)](LICENSE)

Mobile app for substitution/timetables plus weather data of Lessing-Gymnasium Karlsruhe.

## Get the app

- iOS: https://apps.apple.com/app/lgka/id6747010920
- Android: https://play.google.com/store/apps/details?id=com.lgka

## Features

- Substitution plans (today/tomorrow) and official timetables (PDF)
- Integrated PDF viewer with zoom and sharing
- Weather data with smooth charts and stale-data detection
- Dark-only Material Design 3
- Dynamic accent colors across the entire app

## Schedule (Timetables)

How the Schedule screen works (high level):

- Source and access: Securely fetches the page `unterricht/stundenplan` with HTTP Basic Auth and the unified User‑Agent `LGKA-App-Luka-Loehr`.
- Parsing: Extracts links from module `#mod-custom213`, normalizes URLs, and builds entries with half‑year and grade level.
- Caching:
  - List cache: 30 minutes (serves last known data on errors)
  - Availability cache: 15 minutes (lightweight HEAD requests)
- Availability: Checks all items concurrently; if any 2nd half‑year plans are present, 1st half‑year is hidden.
- Download & validation: Authenticated PDF download to a temp file; 404 means “not available yet”; tiny/HTML/invalid PDFs are discarded using header/trailer checks.
- UX: Clear loading/empty/error states, single retry refresh, smooth fade‑ins, footer with version and adaptive bottom padding.

Related code: `lib/services/schedule_service.dart`, `lib/providers/schedule_provider.dart`, `lib/screens/schedule_page.dart`

## Quick Start

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK 3.8.0+
- Android Studio or VS Code with Flutter extensions
- For iOS development: Xcode and CocoaPods

### Installation & Setup

#### End Users
**[Latest Release](https://github.com/luka-loehr/LGKA/releases/latest)** – Android APKs (split-per-ABI) und AAB für den Play Store

#### Developers
```bash
# Clone repository
git clone https://github.com/luka-loehr/LGKA.git
cd LGKA

# Install dependencies
flutter pub get

# Run the app in debug mode
flutter run

# Run on specific device
flutter run -d [device-id]
```

## Development

### Test & Analyze
```bash
# Analyze code for issues
flutter analyze

# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

### Build
```bash
# Build split-per-ABI APKs (arm64-v8a ~21 MB, armeabi-v7a ~19 MB)
flutter build apk --release --split-per-abi

# Build for specific architecture (arm64 only)
flutter build apk --release --target-platform=android-arm64

# Build universal AAB (all ABIs) for Play Store (~47 MB upload; Play liefert Gerätesplits)
flutter build appbundle --release

# Optional: arm64-only AAB (~18 MB)
flutter build appbundle --release --target-platform=android-arm64
```

### Config
```bash
# Update app configuration (icons, version, etc.)
./scripts/update_app_config.sh

# Apply configuration changes from app_config.yaml
dart run scripts/apply_app_config.dart

# Generate app icons
dart run scripts/generate_app_icons.dart
```

### Maintenance
```bash
# Clean build artifacts
flutter clean

# Check outdated dependencies
flutter pub outdated

# Upgrade dependencies
flutter pub upgrade
```

## Architecture (short)

- Layers: `data/` (repos), `services/` (business logic), `providers/` (Riverpod state), `screens/` (UI), `navigation/` (GoRouter)
- PDFs: Syncfusion parsing, pdfx viewer, temp storage
- Weather: CSV source, 10‑min cache, charts
- Auth & Security: HTTP Basic Auth only; settings stored locally

## Stack

- Flutter (stable), Dart 3.8+
- State: flutter_riverpod; Navigation: go_router
- Docs/PDF: syncfusion_flutter_pdf, pdfx, photo_view, share_plus
- Charts/Data: syncfusion_flutter_charts, csv, intl
- Network: http (Basic Auth; User-Agent `LGKA-App-Luka-Loehr`), html parser

## Project Structure

```
lib/
├── screens/      # UI Screens
├── services/     # Business Logic
├── providers/    # State Management
├── data/         # Repositories
└── theme/        # Material Theme
```

## Configuration

### App Configuration
App settings are centralized in `app_config/app_config.yaml`:

- App identity (name, package, description)
- Version management (version_name, version_code)
- Platform-specific settings:
  - **Android**: min_sdk: 21, target_sdk: 36, compile_sdk: 36
  - **iOS**: deployment_target: 12.0
- Icon configuration with automatic generation

Apply changes with: `dart run scripts/apply_app_config.dart`

### Build Configuration
- **Dart SDK**: 3.8.0+
- **Android**: Min SDK 21, Target SDK 36 (via `pubspec.yaml: flutter.targetSdkVersion`)
  - **iOS**: Deployment target 12.0
- **Optimizations**: R8/ProGuard, resource shrinking, tree-shaking
- **APK size (arm64-v8a)**: ~21 MB (split APK); universal AAB ~47 MB; arm64-only AAB ~18 MB (Play delivers device splits)
- **Performance**: Parallel builds, configuration cache, D8

## Guidelines (short)

### Theme & UX
- **Dark-only Material Design 3** with `useMaterial3: true`
- **Appblue** color scheme
- **Haptic feedback** via `HapticService`
- **Edge-to-edge display** with insets for Android 15+

### File Operations
- **Built-in PDF viewer**: Uses pdfx for consistent PDF viewing experience
- **PDF processing**: Syncfusion Flutter PDF for metadata extraction and text parsing
- **Sharing capabilities**: Share PDFs via system share sheet

### Error Handling
- Graceful degradation with offline fallbacks throughout
- User-friendly error messages
- Automatic retry mechanisms for network operations

### Testing
- Unit tests for core business logic
- Widget tests for UI components
- Integration tests for critical user flows

## Troubleshooting

### Common Issues
1. **Build failures**: Run `flutter clean && flutter pub get`
2. **iOS build issues**: Update CocoaPods with `pod repo update`
3. **Android build issues**: Check SDK versions in `android/app/build.gradle`
4. **Network issues**: Verify API endpoints and network permissions

### Performance Tips
- Use `flutter analyze` for code quality checks
- Monitor memory usage during PDF operations
- Optimize chart rendering for large weather datasets

## Contributing

1. Follow the existing code style and architecture patterns
2. Write tests for new features
3. Update documentation for significant changes
4. Use conventional commit messages
5. Ensure all builds pass before submitting PRs

## Privacy & Legal

- No data collection or tracking
- All data remains local on the device
- Secure connection to school server

**[📋 Privacy Policy](privacy.html)** | **[ℹ️ Legal Notice](impressum.html)**

## License

[Creative Commons BY-NC-ND 4.0](LICENSE) – Private student project

**Allowed**: Private use, code study  
**Not allowed**: Commercial use, publication by third parties

## Support

- **Bugs**: [Issues](https://github.com/luka-loehr/LGKA/issues)
- **Questions**: [Email](mailto:contact@lukaloehr.de)

---

Developed by [Luka Löhr](https://github.com/luka-loehr) for the school community of Lessing-Gymnasium Karlsruhe.
