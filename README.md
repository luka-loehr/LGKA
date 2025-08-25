![LGKA+ Banner](app_store_assets/banners/lgka_banner_1024x500.png)

# LGKA+ – Digital Substitution and Timetables

[![Flutter](https://img.shields.io/badge/Flutter-Latest-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=flat)](https://github.com/luka-loehr/LGKA/releases)
[![License](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-orange?style=flat)](LICENSE)

Mobile app for substitution and timetables plus weather data of Lessing-Gymnasium Karlsruhe.

## Features

- **Substitution and timetables**: Automatic fetch (today/tomorrow) and timetables
- **PDF viewer**: Integrated display with zoom and sharing
- **Weather data**: Live data with charts
- **Dark-only design**: Material Design 3
- **Network-based**: Always fetches fresh data from the school server

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

## Development Commands

### Testing & Analysis
```bash
# Analyze code for issues
flutter analyze

# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

### Building
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

### Configuration Management
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

## Architecture

### Core Architecture Pattern
The app follows clean architecture principles with clear separation of concerns:

- **Data Layer** (`lib/data/`): Repositories and preference management
- **State Management** (`lib/providers/`): Riverpod providers for reactive state
- **Services** (`lib/services/`): Business logic for weather data and file handling
- **Presentation** (`lib/screens/`): UI screens with Material Design 3 dark theme
- **Navigation** (`lib/navigation/`): GoRouter-based declarative routing

### Key Implementation Details

#### Network-based architecture
- **Fresh data**: Directly fetched from the school server
- **Preloading**: Parallel loading of PDFs and weather on app start
- **Loading states**: Clear states until requests complete

#### PDF Management
- **Processing**: Syncfusion Flutter PDF for metadata/text in isolates
- **Viewing**: pdfx with PhotoView (zoom/pan)
- **Storage**: Temporary directory, weekday-based filenames
- **Access**: HTTP Basic Auth (school server)

#### Weather data pipeline
- **Source**: School weather station (CSV, UTF-8, `;`)
- **Caching**: 10 minutes in-memory
- **Processing**: Downsampling for performance
- **Visualization**: Syncfusion SplineSeries

#### Auth & Security
- No user accounts; credentials only for server access
- Settings stored locally

### State Management & Providers

**Riverpod-based architecture** with dependency injection and reactive state:

- **`preferencesManagerProvider`**: User settings and authentication state
- **`pdfRepositoryProvider`**: ChangeNotifier for PDF download state with loading indicators
- **`weatherDataProvider`**: StateNotifier managing weather data and loading states

### Navigation Flow

Routes are defined in `lib/navigation/app_router.dart`:

- `/welcome`: First-time user onboarding
- `/auth`: Password authentication screen
- `/`: Home screen with tabs for PDFs and weather
- `/pdf-viewer`: PDF viewing with sharing capabilities
- `/settings`: App preferences
- `/legal`: Legal information and privacy policy

## Tech Stack

### Core Framework
- **Flutter** (latest stable) / **Dart 3.8.0+**
- **flutter_riverpod** - State management
- **go_router** - Navigation
- **shared_preferences** - Local storage
- **path_provider** - File system access

### PDF & Documents
- **syncfusion_flutter_pdf** ^29.2.9 - PDF processing and text extraction
- **pdfx** ^2.9.1 - PDF viewing with zoom/pan capabilities
- **photo_view** ^0.15.0 - Image viewing for PDF pages
- **share_plus** ^11.0.0 - System share functionality

### Charts & Data Visualization
- **syncfusion_flutter_charts** ^29.2.9 - Weather data charts (SplineSeries)
- **csv** ^6.0.0 - CSV parsing for weather data
- **intl** ^0.19.0 - Date/time formatting and internationalization

### Network
- **http** ^1.2.2 – HTTP (Basic Auth, User-Agent: `LGKA-App-Luka-Loehr`)
- **html** ^0.15.4 – HTML parsing (timetables)

### Development & Tooling
- **flutter_launcher_icons** ^0.14.1 - Automated icon generation
- **yaml** ^3.1.2 - Configuration file parsing
- **package_info_plus** ^8.3.0 - App version information

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

## Development Guidelines

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
