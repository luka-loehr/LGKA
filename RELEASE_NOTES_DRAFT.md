iOS: https://apps.apple.com/app/lgka/id6747010920  
Android: https://play.google.com/store/apps/details?id=com.lgka

## Highlights

This update brings significant improvements to the PDF viewer with enhanced class selection, updated launch screens, and better weather data handling. The app now uses Riverpod 3.0 for improved state management and includes various bug fixes and performance improvements.

## What's Changed

### PDF Viewer
- Enhanced class selection experience with visual feedback
- Added button animations and real-time class validation
- Improved auto-navigation with PDF ready checks instead of fixed delays
- Fixed "Speichern" button not turning green when class is successfully entered
- Fixed auto-navigation timing issues after class input
- Enhanced loading spinner animation in schedule class selection modal

### Weather Screen
- Shows timezone-aware data collection status (0:00-1:00 AM German time)
- Added repair mode detection for weather station (shows maintenance message when needed)
- Weather chart improvements: full day display, better x-axis intervals, improved titles
- Added safeguards to prevent app freezing on large or corrupted CSV files

### Schedule & Timetables
- Schedule PDFs now preload automatically for faster access
- Improved schedule search UX with better orientation handling

### UI & Design
- Launch screens now display app logo on both iOS and Android platforms
- Updated iOS and Android launch screens with improved visual consistency
- Privacy consent footer added to welcome screen
- Enhanced error handling: global error catcher, custom ErrorWidget, and friendly UI messages

### Under the Hood
- Migrated to Riverpod 3.0 with improved state management
- Major dependency updates: flutter_riverpod 3.0.3, syncfusion packages 31.2.18, go_router 17.0.1, timezone 0.10.1
- iOS project configuration updates and suppressed deprecation warnings from third-party plugins
- Fixed Android Gradle plugin version compatibility
- Fixed widget test: mock services and SharedPreferences to prevent network calls
- Fixed linter issues: remove unused imports/fields, replace print with debugPrint
- Fixed email link formatting in privacy.html
- Cleaned up weather service security checks

## Version Info
- Version: 2.3.0 (Build 281)
- Platforms: iOS 13.0+, Android 7.0+

---

## Legal
Developer: Luka Löhr  
Imprint: https://luka-loehr.github.io/LGKA/impressum.html  
Privacy: https://luka-loehr.github.io/LGKA/privacy.html

This is an unofficial helper app for students of Lessing-Gymnasium Karlsruhe and is not directly affiliated with the school administration.
