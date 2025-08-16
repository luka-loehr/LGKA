# LGKA+ – Digital Substitution Schedule

[![Flutter](https://img.shields.io/badge/Flutter-Latest-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=flat)](https://github.com/luka-loehr/LGKA/releases)
[![License](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-orange?style=flat)](LICENSE)

Mobile app for the digital substitution schedule of Lessing-Gymnasium Karlsruhe.

## Features

- **Substitution Schedule**: Automatic download for today and tomorrow with offline availability
- **PDF Viewer**: Integrated display with zoom, sharing and external app integration
- **Weather Data**: Live data from the school weather station with charts
- **Dark-Only Design**: Eye-friendly Material Design 3 theme
- **Offline-First**: Intelligent caching with automatic network detection

## Quick Start

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK 3.8.0+
- Android Studio or VS Code with Flutter extensions
- For iOS development: Xcode and CocoaPods

### Installation & Setup

#### End Users
**[Latest Release](https://github.com/luka-loehr/LGKA/releases/latest)** – ARM64 APK for Android 5.0+

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
# Build optimized APK (~10MB per architecture)
flutter build apk --release --split-per-abi

# Build for specific architecture
flutter build apk --release --target-platform=android-arm64

# Build for Play Store
flutter build appbundle --release
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
- **Services** (`lib/services/`): Business logic for offline caching, weather data, and file handling
- **Presentation** (`lib/screens/`): UI screens with Material Design 3 dark theme
- **Navigation** (`lib/navigation/`): GoRouter-based declarative routing

### Key Implementation Details

#### Offline-First Architecture
- **Smart caching**: 3-second slow connection detection with automatic offline fallback
- **Dual cache system**: Temporary cache + persistent offline cache via `OfflineCache` service
- **Preloading**: Parallel PDF and weather data loading on app start
- **Network detection**: `connectivity_plus` integration with automatic retry timers

#### PDF Management System
- **Processing**: Syncfusion Flutter PDF for metadata extraction and text parsing in isolates
- **Viewing**: pdfx with PhotoView for zoom/pan capabilities and custom transitions
- **Caching**: Weekday-based naming with legacy fallback, stored in temporary directory
- **Authentication**: HTTP Basic Auth for school server access

#### Weather Data Pipeline
- **Source**: School weather station CSV data (`;` delimited, UTF-8 encoded)
- **Caching**: 10-minute cache validity with in-memory + persistent storage
- **Processing**: Data downsampling for chart performance (adaptive sampling rates)
- **Visualization**: Syncfusion SplineSeries charts with Material 3 theming and tooltips

#### Authentication & Security
- Simple credential-based authentication (hardcoded for school use)
- Session management with automatic logout
- Secure preference storage for user settings

### State Management & Providers

**Riverpod-based architecture** with dependency injection and reactive state:

- **`preferencesManagerProvider`**: User settings and authentication state
- **`pdfRepositoryProvider`**: ChangeNotifier for PDF download/cache state with loading indicators
- **`weatherDataProvider`**: StateNotifier managing weather data, offline mode, and retry logic
- **`reviewServiceProvider`**: In-app review prompts based on usage patterns
- **`connectivityProvider`**: Network state monitoring with automatic reconnection

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
- **open_filex** ^4.5.0 - Cross-platform file opening
- **share_plus** ^11.0.0 - System share functionality

### Charts & Data Visualization
- **syncfusion_flutter_charts** ^29.2.9 - Weather data charts (SplineSeries)
- **csv** ^6.0.0 - CSV parsing for weather data
- **intl** ^0.19.0 - Date/time formatting and internationalization

### Network & Connectivity
- **http** ^1.2.2 - HTTP requests with Basic Auth
- **connectivity_plus** ^6.1.0 - Network state monitoring

### Development & Tooling
- **flutter_launcher_icons** ^0.14.1 - Automated icon generation
- **yaml** ^3.1.2 - Configuration file parsing
- **package_info_plus** ^8.3.0 - App version information
- **in_app_review** ^2.0.8 - App Store review prompts

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
  - **Android**: min_sdk: 21, target_sdk: 34, compile_sdk: 34
  - **iOS**: deployment_target: 12.0
- Icon configuration with automatic generation

Apply changes with: `dart run scripts/apply_app_config.dart`

### Build Configuration
- **Dart SDK**: 3.8.0+
- **Android**: Min SDK 21, Target SDK 34 (configurable via app_config.yaml)
- **iOS**: Deployment target 12.0
- **Optimizations**: R8 full mode enabled, resource optimization, tree-shaking
- **APK Size**: Split APKs reduce download to ~10MB per architecture
- **Performance**: Parallel builds, configuration caching, D8 desugaring enabled

## Development Guidelines

### Theme & UX
- **Dark-only Material Design 3** theme with `useMaterial3: true`
- **Custom color scheme** based on pure black background (#000000) and blue accents (#3770D4)
- **Haptic feedback** abstracted through `HapticService` for cross-platform tactile responses
- **Edge-to-edge display** with proper inset handling for Android 15+ compatibility

### File Operations
- **`FileOpenerService`** handles cross-platform PDF opening (macOS: `open`, mobile: `open_filex`)
- **Dual PDF viewing modes**: Built-in viewer (pdfx) or external apps (user preference)
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
- **Questions**: [Email](mailto:lgka.vertretungsplan@gmail.com)

---

Developed by [Luka Löhr](https://github.com/luka-loehr) for the school community of Lessing-Gymnasium Karlsruhe.
