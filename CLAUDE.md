# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run on specific device
flutter run -d [device-id]

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Build APK (optimized ~10MB per architecture)
flutter build apk --release --split-per-abi

# Build APK for specific architecture
flutter build apk --release --target-platform=android-arm64

# Build for Play Store
flutter build appbundle --release

# Update app configuration (icons, version, etc.)
./scripts/update_app_config.sh

# Apply configuration changes from app_config.yaml
dart run scripts/apply_app_config.dart

# Clean build artifacts
flutter clean

# Deep clean on macOS
./clean_deep_mac.sh

# Check outdated dependencies
flutter pub outdated

# Upgrade dependencies
flutter pub upgrade
```

## High-Level Architecture

This is a Flutter app for the digital substitution schedule of Lessing-Gymnasium Karlsruhe, built with an offline-first approach.

### Core Architecture Pattern
The app follows a clean architecture with clear separation:
- **Data Layer** (`lib/data/`): Repositories and preference management
- **State Management** (`lib/providers/`): Riverpod providers for reactive state
- **Services** (`lib/services/`): Business logic for features like offline caching, weather data, and file handling
- **Presentation** (`lib/screens/`): UI screens with Material Design 3 dark theme
- **Navigation** (`lib/navigation/`): GoRouter-based declarative routing

### Key Architectural Decisions

1. **State Management**: Uses Riverpod throughout for dependency injection and reactive state. Main providers are in `lib/providers/app_providers.dart`:
   - `preferencesManagerProvider`: Manages user preferences
   - `pdfRepositoryProvider`: Handles PDF state and caching
   - `weatherDataProvider`: StateNotifier for weather data with offline fallback
   - `reviewServiceProvider`: Manages app review prompts
   - Authentication and navigation state providers

2. **Offline-First Design**: 
   - `OfflineCacheService` (`lib/services/offline_cache_service.dart`) handles intelligent caching with network detection
   - Automatic fallback to cached data when offline
   - Preloading of PDFs and weather data on app start
   - Weather data includes retry timer when offline (5-second intervals)

3. **PDF Handling**: 
   - `PdfRepository` (`lib/data/pdf_repository.dart`) manages PDF caching and state
   - Uses Syncfusion Flutter PDF for processing and pdfx for viewing
   - PDFs are cached in app documents directory with date tracking
   - Automatic download and caching for today/tomorrow PDFs

4. **Weather Feature**:
   - `WeatherService` fetches data from school weather station API
   - `WeatherDataNotifier` manages state with automatic retries and offline mode
   - Data downsampling for chart performance (reduces data points for visualization)
   - Charts displayed using Syncfusion Charts with Material 3 theming
   - Offline cache persists last known weather data

5. **Navigation Flow** (`lib/navigation/app_router.dart`):
   - `/welcome`: First-time user onboarding
   - `/auth`: Password authentication screen
   - `/`: Home screen with tabs for PDFs and weather
   - `/pdf-viewer`: PDF viewing with sharing capabilities
   - `/settings`: App preferences
   - `/legal`: Legal information and privacy policy

### Configuration Management

App configuration is centralized in `app_config/app_config.yaml`:
- App identity (name, package, description)
- Version management (version_name, version_code)
- Platform-specific settings:
  - Android: min_sdk: 21, target_sdk: 34 (managed via pubspec variable)
  - iOS: deployment_target: 12.0
- Icon configuration with automatic generation

Apply changes with: `dart run scripts/apply_app_config.dart`

### Important Implementation Details

- **Theme**: Dark-only Material Design 3 theme defined in `lib/theme/app_theme.dart`
- **Haptic Feedback**: Abstracted through `HapticService` for cross-platform support
- **File Operations**: 
  - `FileOpenerService` handles PDF opening and sharing
  - Support for both internal viewer and external apps
- **Network Detection**: Uses `connectivity_plus` for offline/online state
- **Preferences**: Managed through `PreferencesManager` with shared_preferences
- **Error Handling**: Graceful degradation with offline fallbacks throughout

### Key Dependencies

- **State Management**: flutter_riverpod ^2.6.1
- **Navigation**: go_router ^15.1.2
- **PDF**: syncfusion_flutter_pdf, pdfx
- **Charts**: syncfusion_flutter_charts
- **Network**: http ^1.2.2, connectivity_plus ^6.1.0
- **Storage**: shared_preferences ^2.3.4, path_provider
- **UI**: google_fonts, flutter_svg, shimmer

### Build Considerations

- Minimum Dart SDK: 3.8.0
- Android: Min SDK 21, Target SDK 36 (via pubspec variable)
- iOS: Deployment target 12.0
- R8 optimization enabled for smaller APK sizes
- Split APKs reduce download size to ~10MB per architecture
- ProGuard rules configured for release builds