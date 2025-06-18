# 🛠️ Entwicklungsumgebung

Diese Anleitung richtet sich an Entwickler, die an der LGKA+ App mitarbeiten oder den Code verstehen möchten.

## Voraussetzungen

### Software-Requirements

- **Flutter SDK**: 3.8.0 oder neuer
- **Dart SDK**: 3.8.1 oder neuer
- **Git**: 2.20 oder neuer
- **Android Studio** oder **VS Code** mit Flutter-Plugin

### Plattform-spezifisch

**Android-Entwicklung:**
- **Android SDK**: API Level 21+ (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Java/Kotlin**: Für Android-spezifische Implementierungen

**iOS-Entwicklung:**
- **Xcode**: Neueste Version
- **iOS Deployment Target**: 12.0+
- **macOS**: Für iOS-Development erforderlich

## Projekt-Setup

### Repository klonen

```bash
git clone https://github.com/luka-loehr/LGKA.git
cd LGKA
```

### Dependencies installieren

```bash
flutter pub get
```

### App-Icons generieren

```bash
dart run generate_app_icons.dart
```

### Entwicklung starten

```bash
# Debug-Modus mit Hot Reload
flutter run --debug

# Für Release-Testing
flutter run --release
```

## Projekt-Architektur

### Verzeichnisstruktur

```
lib/
├── data/               # Datenmanagement
│   ├── pdf_repository.dart     # PDF-Download und Caching
│   └── preferences_manager.dart # App-Einstellungen
├── navigation/         # Navigation & Routing
│   └── app_router.dart
├── providers/          # State Management
│   ├── app_providers.dart      # Riverpod Provider
│   └── haptic_service.dart     # Haptisches Feedback
├── screens/           # UI-Screens
│   ├── auth_screen.dart        # Anmelde-Bildschirm
│   ├── home_screen.dart        # Hauptbildschirm
│   ├── pdf_viewer_screen.dart  # PDF-Anzeige
│   ├── settings_screen.dart    # Einstellungen
│   ├── welcome_screen.dart     # Willkommens-Screen
│   └── legal_screen.dart       # Rechtliche Hinweise
├── services/          # Externe Services
│   ├── file_opener_service.dart # Datei-Öffnung
│   └── review_service.dart      # In-App-Review
├── theme/             # App-Design
│   └── app_theme.dart          # Material Design 3
└── main.dart          # App-Einstiegspunkt
```

### Technologie-Stack

**Frontend Framework:**
- **Flutter**: Cross-Platform UI
- **Material Design 3**: Design-System mit Dark Theme

**State Management:**
- **Riverpod**: Reaktive State-Verwaltung
- **SharedPreferences**: Lokale Einstellungen

**Navigation:**
- **go_router**: Deklarative Navigation mit Animationen

**PDF-Verarbeitung:**
- **Syncfusion PDF**: Metadaten-Extraktion
- **PDFx**: Hochperformante PDF-Anzeige

## Build-System

### Development Builds

**Android (ARM64 - empfohlen):**
```bash
flutter build apk --release --target-platform=android-arm64
```

**Installation via ADB:**
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Production Builds

**Google Play Store:**
```bash
flutter build appbundle --release
```

**iOS App Store:**
```bash
flutter build ios --release
```

## App-Konfiguration

### Zentrale Konfiguration

Die App verwendet ein zentrales Konfigurationssystem in `app_config/app_config.yaml`:

```yaml
app_name: "LGKA+"
package_name: "com.lgka"
version_name: "2.0.1"
version_code: "28"
```

### Konfiguration anwenden

```bash
# Automatische Anwendung auf Android und iOS
dart run scripts/apply_app_config.dart
```

## Key Dependencies

### Core Packages

```yaml
# State Management
flutter_riverpod: ^2.6.1

# Navigation  
go_router: ^15.1.2

# Network & Connectivity
http: ^1.2.2
connectivity_plus: ^6.1.0

# PDF Processing
syncfusion_flutter_pdf: ^29.2.9
pdfx: ^2.9.1

# Local Storage
shared_preferences: ^2.3.4

# File Handling
open_filex: ^4.5.0
share_plus: ^11.0.0

# User Experience
in_app_review: ^2.0.8
```

## Entwicklungs-Workflow

### Code-Standards

**Dart/Flutter Conventions:**
- Befolge die [Flutter Style Guide](https://flutter.dev/docs/development/style-guide)
- Verwende `flutter analyze` für Code-Qualität
- Formatiere Code mit `dart format`

**Git Workflow:**
- Verwende aussagekräftige Commit-Messages
- Keine Prefixe in Commit-Messages (wie "fix:", "feat:")
- Ein Feature pro Commit

### Testing

```bash
# Unit Tests
flutter test

# Widget Tests  
flutter test test/widget_test.dart

# Integration Tests (Device erforderlich)
flutter test integration_test/
```

### Debug-Modi

**Navigation Debug:**
- In den App-Einstellungen aktivierbar
- Zeigt Erkennungsdetails für Button-/Gesture-Navigation

**PDF Debug:**
- Logging für PDF-Download und Metadaten-Extraktion
- Über `debugPrint()` in der Console sichtbar

## Build-Optimierungen

### Android

**R8 Code Shrinking:**
```gradle
android {
    buildTypes {
        release {
            shrinkResources true
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

**Icon Tree-Shaking:**
- Reduziert Font-Größe um 99%+ durch Entfernung ungenutzter Icons

### Performance

**Background Isolates:**
- PDF-Verarbeitung läuft in separaten Isolates
- Verhindert UI-Blocking bei großen PDF-Dateien

**Intelligentes Caching:**
- Wochentag-basierte Dateinamen (`montag.pdf`, `dienstag.pdf`)
- Automatische Bereinigung alter Dateien

## Debugging & Profiling

### Flutter DevTools

```bash
# DevTools starten
flutter pub global run devtools

# App mit DevTools verbinden
flutter run --debug
```

### Performance Profiling

```bash
# Performance-Profiling
flutter run --profile

# Memory-Analyse
flutter run --debug --enable-dart-profiling
```

### Network Debugging

Die App loggt alle Netzwerk-Aktivitäten:
- PDF-Download-Status
- Verbindungsgeschwindigkeit
- Auto-Retry-Mechanismus

## Contribution Guidelines

### Pull Requests

1. **Fork** des Repositories erstellen
2. **Feature Branch** für neue Funktionen
3. **Ausführliche Beschreibung** der Änderungen
4. **Tests** für neue Funktionen hinzufügen

### Issue Reporting

**Bug Reports:**
- Schritte zur Reproduktion
- Erwartetes vs. tatsächliches Verhalten
- Screenshots/Videos bei UI-Issues

**Feature Requests:**
- Detaillierte Beschreibung der gewünschten Funktionalität
- Use Cases und Nutzen für andere User

---

**Entwickler-Kontakt:** lgka.vertretungsplan@gmail.com