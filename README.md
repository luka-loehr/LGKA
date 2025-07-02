# LGKA+ – Digital Substitution Schedule

[![Flutter](https://img.shields.io/badge/Flutter-3.8.0+-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=flat)](https://github.com/luka-loehr/LGKA/releases)
[![License](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-orange?style=flat)](LICENSE)

Mobile app for the digital substitution schedule of Lessing-Gymnasium Karlsruhe.

## Features

- **Substitution Schedule**: Automatic download for today and tomorrow with offline availability
- **PDF Viewer**: Integrated display with zoom, sharing and external app integration  
- **Weather Data**: Live data from the school weather station with charts
- **Dark Mode**: Eye-friendly Material Design 3 theme
- **Offline-First**: Intelligent caching with automatic network detection

## Installation

### End Users
**[Latest Release](https://github.com/luka-loehr/LGKA/releases/latest)** – ARM64 APK for Android 5.0+

### Developers
```bash
# Clone repository
git clone https://github.com/luka-loehr/LGKA.git
cd lgka_flutter

# Install dependencies
flutter pub get

# Start app
flutter run
```

## Build

```bash
# Development (ARM64 APK ~10MB)
flutter build apk --release --target-platform=android-arm64

# Production (App Bundle for Play Store)
flutter build appbundle --release
```

## Tech Stack

- **Flutter 3.8.0+** / Dart 3.8.1+
- **State Management**: Riverpod
- **Navigation**: go_router  
- **PDF**: Syncfusion PDF + pdfx
- **Charts**: Syncfusion Charts

## Project Structure

```
lib/
├── screens/      # UI Screens
├── services/     # Business Logic
├── providers/    # State Management
├── data/         # Repositories
└── theme/        # Material Theme
```

## Privacy

- No data collection or tracking
- All data remains local on the device
- Secure connection to school server

**[📋 Privacy Policy](privacy.html)** | **[ℹ️ Legal Notice](impressum.html)**

## Legal

- **[Privacy Policy](privacy.html)** – Privacy and user data
- **[Legal Notice](impressum.html)** – Legal information about the project

## License

[Creative Commons BY-NC-ND 4.0](LICENSE) – Private student project

**Allowed**: Private use, code study  
**Not allowed**: Commercial use, publication by third parties

## Support

- **Bugs**: [Issues](https://github.com/luka-loehr/LGKA/issues)
- **Questions**: [Discussions](https://github.com/luka-loehr/LGKA/discussions)
- **Docs**: [Wiki](https://github.com/luka-loehr/LGKA/wiki)

---

Developed by [Luka Löhr](https://github.com/luka-loehr) for the school community of Lessing-Gymnasium Karlsruhe.
