# LGKA+ – Digital Substitution Schedule

[![Flutter](https://img.shields.io/badge/Flutter-Latest-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=flat)](https://github.com/luka-loehr/LGKA/releases)
[![License](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-orange?style=flat)](LICENSE)

Mobile app for the digital substitution schedule of Lessing-Gymnasium Karlsruhe.

## Features

- **Substitution Schedule**: Automatic download for today and tomorrow with offline availability
- **PDF Viewer**: Integrated display with zoom, sharing and external app integration
- **Weather Data**: Live data from the school weather station with charts
- **Dark Mode**: Eye-friendly Material Design 3 theme
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

#### Offline-First Design
- Intelligent caching with network detection and automatic fallback
- Preloading of PDFs and weather data on app start
- 5-second retry intervals for weather data when offline

#### PDF Management
- Automatic download and caching for today/tomorrow schedules
- Syncfusion Flutter PDF for processing, pdfx for viewing
- Date-tracked caching in app documents directory

#### Weather Integration
- Real-time data from school weather station API
- Data downsampling for chart performance optimization
- Syncfusion Charts with Material 3 theming

#### Authentication & Security
- Password-based authentication with secure preference storage
- Session management with automatic logout

### State Management

The app uses Riverpod throughout for dependency injection and reactive state. Main providers are located in `lib/providers/app_providers.dart`:

- `preferencesManagerProvider`: Manages user preferences
- `pdfRepositoryProvider`: Handles PDF state and caching
- `weatherDataProvider`: StateNotifier for weather data with offline fallback
- `reviewServiceProvider`: Manages app review prompts
- Authentication and navigation state providers

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
- **syncfusion_flutter_pdf** - PDF processing
- **pdfx** - PDF viewing
- **file_picker** - File selection

### Charts & Visualization
- **syncfusion_flutter_charts** - Weather data charts

### Network & Connectivity
- **http** - HTTP requests
- **connectivity_plus** - Network detection

### UI & Design
- **google_fonts** - Typography
- **flutter_svg** - SVG support
- **shimmer** - Loading animations

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
  - Android: min_sdk: 21, target_sdk: 34
  - iOS: deployment_target: 12.0
- Icon configuration with automatic generation

Apply changes with: `dart run scripts/apply_app_config.dart`

### Build Configuration
- Minimum Dart SDK: 3.8.0
- Android: Min SDK 21, Target SDK 36
- iOS: Deployment target 12.0
- R8 optimization enabled for smaller APK sizes
- Split APKs reduce download size to ~10MB per architecture
- ProGuard rules configured for release builds

## Development Guidelines

### Theme
- Dark-only Material Design 3 theme defined in `lib/theme/app_theme.dart`
- Consistent color scheme throughout the app
- Haptic feedback abstracted through `HapticService`

### File Operations
- `FileOpenerService` handles PDF opening and sharing
- Support for both internal viewer and external apps
- Graceful error handling with user feedback

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
