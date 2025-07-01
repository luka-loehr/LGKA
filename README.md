# LGKA+ – Digitaler Vertretungsplan

[![Flutter](https://img.shields.io/badge/Flutter-3.8.0+-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=flat)](https://github.com/luka-loehr/LGKA/releases)
[![License](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-orange?style=flat)](LICENSE)

Mobile App für den digitalen Vertretungsplan des Lessing-Gymnasiums Karlsruhe.

## Features

- **Vertretungsplan**: Automatischer Download für heute und morgen mit Offline-Verfügbarkeit
- **PDF-Viewer**: Integrierte Anzeige mit Zoom, Sharing und externer App-Integration  
- **Wetterdaten**: Live-Daten von der Schulwetterstation mit Diagrammen
- **Dark Mode**: Augenschonendes Material Design 3 Theme
- **Offline-First**: Intelligentes Caching mit automatischer Netzwerkerkennung

## Installation

### Endnutzer
**[Latest Release](https://github.com/luka-loehr/LGKA/releases/latest)** – ARM64 APK für Android 5.0+

### Entwickler
```bash
# Repository klonen
git clone https://github.com/luka-loehr/LGKA.git
cd lgka_flutter

# Dependencies installieren
flutter pub get

# App starten
flutter run
```

## Build

```bash
# Development (ARM64 APK ~10MB)
flutter build apk --release --target-platform=android-arm64

# Production (App Bundle für Play Store)
flutter build appbundle --release
```

## Tech Stack

- **Flutter 3.8.0+** / Dart 3.8.1+
- **State Management**: Riverpod
- **Navigation**: go_router  
- **PDF**: Syncfusion PDF + pdfx
- **Charts**: Syncfusion Charts

## Projektstruktur

```
lib/
├── screens/      # UI Screens
├── services/     # Business Logic
├── providers/    # State Management
├── data/         # Repositories
└── theme/        # Material Theme
```

## Datenschutz

- Keine Datensammlung oder Tracking
- Alle Daten bleiben lokal auf dem Gerät
- Sichere Verbindung zum Schulserver

**[📋 Datenschutzerklärung](privacy.html)** | **[ℹ️ Impressum](impressum.html)**

## Rechtliches

- **[Datenschutzerklärung](privacy.html)** – Datenschutz und Nutzerdaten
- **[Impressum](impressum.html)** – Rechtliche Angaben zum Projekt

## Lizenz

[Creative Commons BY-NC-ND 4.0](LICENSE) – Privates Schülerprojekt

**Erlaubt**: Private Nutzung, Code-Studium  
**Nicht erlaubt**: Kommerzielle Nutzung, Veröffentlichung durch Dritte

## Support

- **Bugs**: [Issues](https://github.com/luka-loehr/LGKA/issues)
- **Fragen**: [Discussions](https://github.com/luka-loehr/LGKA/discussions)
- **Docs**: [Wiki](https://github.com/luka-loehr/LGKA/wiki)

---

Entwickelt von [Luka Löhr](https://github.com/luka-loehr) für die Schulgemeinschaft des Lessing-Gymnasiums Karlsruhe.
