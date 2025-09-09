# agents.md

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

LGKA+ is a Flutter mobile application for Lessing-Gymnasium Karlsruhe that provides digital access to substitution plans, timetables, and weather data. The app is designed for students and staff to easily access school information on their mobile devices.

## Technology Stack

- **Framework**: Flutter 3.8+ with Dart
- **State Management**: Riverpod for reactive state management
- **Navigation**: GoRouter for declarative routing
- **UI**: Material Design 3 with dark theme
- **Platforms**: Android (API 21+) and iOS (12.0+)
- **Localization**: German only (flutter_localizations)
- **Storage**: SharedPreferences for local data persistence
- **Network**: HTTP client for web scraping and API calls
- **PDF Processing**: Syncfusion Flutter PDF and PDFx for PDF viewing
- **Charts**: Syncfusion Flutter Charts for weather visualization

## Architecture & Structure

### File Organization
```
LGKA/
├── lib/
│   ├── main.dart              # App entry point and initialization
│   ├── data/                  # Data models and managers
│   ├── l10n/                  # Localization files
│   ├── navigation/            # App routing configuration
│   ├── providers/             # Riverpod state providers
│   ├── screens/               # UI screens and pages
│   ├── services/              # Business logic services
│   └── theme/                 # App theming and styling
├── android/                   # Android-specific configuration
├── ios/                       # iOS-specific configuration
├── assets/                    # App assets (images, icons)
├── app_config/                # Cross-platform configuration
├── scripts/                   # Build and deployment scripts
├── docs/                      # Documentation
└── pubspec.yaml              # Flutter dependencies and configuration
```

### Key Components

1. **Authentication System**: Simple authentication for school access
2. **Schedule Service**: Web scraping for substitution plans and timetables
3. **Weather Service**: Weather data integration with charts
4. **PDF Viewer**: Integrated PDF viewing with zoom and share functionality
5. **Preferences Manager**: Local data persistence and user settings
6. **Retry Service**: Network error handling and retry logic

## Development Workflow

### Prerequisites
- Flutter SDK 3.8+
- Dart SDK
- Android Studio / Xcode for platform-specific development
- Git for version control

### Running Locally
```bash
# Clone the repository
git clone https://github.com/luka-loehr/LGKA.git
cd LGKA

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d android
flutter run -d ios
```

### Building for Production
```bash
# Build Android APK
flutter build apk --release

# Build iOS app
flutter build ios --release

# Build app bundle for Play Store
flutter build appbundle --release
```

## Important Development Notes

1. **School-Specific**: This app is designed specifically for Lessing-Gymnasium Karlsruhe
2. **Web Scraping**: Uses web scraping to fetch data from school website
3. **Authentication**: Simple username/password authentication (hardcoded for school access)
4. **Offline Support**: Caches data locally for offline access
5. **Material Design 3**: Uses dark theme exclusively
6. **German Localization**: Only supports German language

## Code Style Guidelines

- Follow Flutter/Dart conventions
- Use Riverpod for state management
- Implement proper error handling
- Add comprehensive logging for debugging
- Use meaningful variable and function names
- Comment complex business logic
- Follow Material Design 3 guidelines

## Key Services

### ScheduleService
- Web scrapes school website for substitution plans
- Handles PDF downloads and caching
- Manages authentication with school system
- Implements retry logic for network failures

### WeatherService
- Fetches weather data from external API
- Creates weather charts using Syncfusion
- Handles data validation and error states

### PreferencesManager
- Manages local app preferences
- Handles first launch detection
- Manages authentication state
- Stores user settings

## Platform-Specific Considerations

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34
- Uses adaptive icons
- Supports edge-to-edge display

### iOS
- Minimum deployment target: 12.0
- Bundle identifier: com.lgka
- Uses development team for signing
- Supports App Store distribution

## Testing

- Unit tests for business logic
- Widget tests for UI components
- Integration tests for critical user flows
- Test on both Android and iOS devices

## Deployment

- **Android**: Deploy to Google Play Store
- **iOS**: Deploy to Apple App Store
- **Version Management**: Update version in pubspec.yaml
- **App Icons**: Generated using flutter_launcher_icons

## Security Considerations

- Web scraping credentials are hardcoded (school-specific)
- No sensitive user data is stored
- All network requests use HTTPS
- PDF files are cached locally for offline access

## Troubleshooting

- Check Flutter doctor for environment issues
- Verify device/emulator connectivity
- Check school website availability
- Review logs for network errors
- Ensure proper authentication credentials

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following Flutter conventions
4. Test on both Android and iOS
5. Submit a pull request

## License

Creative Commons BY-NC-ND 4.0 - Private student project
