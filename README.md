# 📱 LGKA+ – Digitaler Vertretungsplan für das Lessing-Gymnasium Karlsruhe

![Flutter](https://img.shields.io/badge/Flutter-3.8.0+-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.8.1+-0175C2?style=flat&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=flat)
![Version](https://img.shields.io/badge/Version-2.0.1-blue?style=flat)
![License](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-orange?style=flat)

> **Modern Flutter App für den digitalen Vertretungsplan**  
> Entwickelt für die Schulgemeinschaft des Lessing-Gymnasiums Karlsruhe

---

## ✨ Features im Überblick

### � **Intelligenter Vertretungsplan**
- **Automatischer Download** für heute und morgen
- **Offline-Verfügbarkeit** durch smartes PDF-Caching 
- **Wochentag-basierte Dateiverwaltung** (z.B. `montag.pdf`, `dienstag.pdf`)
- **HTTP Basic Authentication** mit verschlüsselter Übertragung
- **Metadaten-Extraktion** aus PDFs (Datum, Uhrzeit, Wochentag)

### 📄 **PDF-Integration**
- **Integrierter PDF-Viewer** mit Zoom & Scroll-Support
- **Externe App-Integration** (Adobe Reader, Google Drive, etc.)
- **PDF-Sharing-Funktion** für einfache Weiterleitung
- **Background-Verarbeitung** für optimale Performance

### 🎨 **Benutzeroberfläche**
- **Material Design 3** mit konsistentem Dark Mode
- **Edge-to-Edge Display** (Android 15+ kompatibel)
- **Adaptive Keyboard-Animation** für optimale UX
- **Flüssige Navigation** mit benutzerdefinierten Animationen
- **Haptisches Feedback** für bessere Interaktion

### ⚙️ **Erweiterte Einstellungen**
- **Flexible Datumsauswahl** (heute, morgen, benutzerdefiniert)
- **PDF-Viewer-Konfiguration** (intern/extern)
- **Authentifizierungsmanagement** 
- **App-Informationen** und Rechtliche Hinweise

### 🌐 **Intelligente Netzwerkverwaltung**
- **Automatische Verbindungserkennung** 
- **Exponentielles Auto-Retry** bei Verbindungsproblemen
- **Slow-Connection-Detection** mit Nutzer-Feedback
- **Offline-First Architektur** für zuverlässige Verfügbarkeit

### � **Zusätzliche Features**
- **Willkommensbildschirm** beim ersten Start
- **In-App-Review-System** für Feedback
- **Adaptive App-Icons** für Android und iOS
- **Umfassende Error-Behandlung** mit Nutzer-freundlichen Meldungen

---

## 🏗️ Technische Architektur

### 🎯 **Framework & Sprachen**
- **Flutter SDK**: 3.8.0+ (Dart 3.8.1+)
- **Material Design 3** mit Custom Dark Theme
- **Kotlin** für Android-spezifische Implementierungen
- **Swift** für iOS-Konfiguration

### 🗂️ **Projektstruktur**
```
lib/
├── screens/          # 6 Haupt-Screens (Welcome, Auth, Home, etc.)
├── services/         # File-Opener & Review-Service
├── providers/        # Riverpod State Management & Haptic Service
├── navigation/       # go_router Navigation mit Animationen
├── data/            # PDF Repository & Preferences Manager
└── theme/           # Custom Material Design 3 Theme
```

### 📦 **Haupt-Dependencies**
| Package | Version | Verwendung |
|---------|---------|------------|
| `flutter_riverpod` | ^2.6.1 | State Management |
| `go_router` | ^15.1.2 | Navigation & Routing |
| `http` | ^1.2.2 | Netzwerkkommunikation |
| `syncfusion_flutter_pdf` | ^29.2.9 | PDF-Verarbeitung |
| `pdfx` | ^2.9.1 | PDF-Anzeige |
| `connectivity_plus` | ^6.1.0 | Netzwerkstatus |
| `share_plus` | ^11.0.0 | PDF-Sharing |
| `shared_preferences` | ^2.3.4 | Lokale Datenspeicherung |

### ⚡ **Performance-Optimierungen**

#### **Build-Optimierungen**
- **R8 Full Mode** für Dead-Code-Eliminierung
- **Resource Shrinking** entfernt ungenutzte Ressourcen  
- **Icon Tree-Shaking** reduziert Schriftarten um 99%+
- **ProGuard** für Code-Optimierung
- **Split APKs** für minimale Download-Größen

#### **Runtime-Optimierungen**
- **Background Isolates** für PDF-Verarbeitung
- **Intelligentes Caching** mit Wochentag-Namen
- **Lazy Loading** für bessere Startup-Performance
- **Connection Pooling** für Netzwerk-Requests

#### **App-Größen**
| Build-Typ | Größe | Verwendung |
|-----------|-------|------------|
| App Bundle | ~45MB | Google Play Store (optimiert auf ~9MB) |
| ARM64 APK | ~9.9MB | Development/Testing |
| ARMv7 APK | ~9.5MB | Legacy-Geräte |
| x86_64 APK | ~10.0MB | Emulator/Testing |

---

## � Installation & Entwicklung

### 📋 **Voraussetzungen**
```bash
Flutter SDK >= 3.8.0
Dart SDK >= 3.8.1
Android SDK >= 21 (Android 5.0)
iOS >= 12.0
```

### 🚀 **Setup**
```bash
# Repository klonen
git clone https://github.com/luka-loehr/LGKA.git
cd LGKA

# Dependencies installieren
flutter pub get

# App-Icons generieren
dart run generate_app_icons.dart

# App starten (Debug)
flutter run
```

### 🏗️ **Build-Kommandos**

#### **Development Builds**
```bash
# Split APKs für lokales Testing (~9.6MB pro Architektur)
flutter build apk --release --split-per-abi

# Installation via ADB (ARM64 empfohlen)
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

#### **Production Builds**
```bash
# Google Play Store
flutter build appbundle --release

# Apple App Store
flutter build ios --release
```

### 🔧 **App-Konfiguration**
Die zentrale Konfiguration erfolgt über `app_config/app_config.yaml`:

```yaml
app_name: "LGKA+"
package_name: "com.lgka"
version_name: "2.0.1"
version_code: "28"
```

Änderungen werden automatisch auf Android und iOS angewendet.

---

## 📱 Platform-spezifische Features

### 🤖 **Android**
- **Edge-to-Edge Display** mit Android 15+ Kompatibilität
- **Adaptive Icons** mit transparentem Hintergrund
- **Material You** Integration
- **Signing Configuration** für Production Releases

### 🍎 **iOS**
- **App Icon Sets** für alle Gerätegrößen
- **Launch Screen** mit korrekten Proportionen
- **Bundle Identifier**: `com.lgka`
- **iOS Deployment Target**: 12.0+

---

## 🔐 Datenschutz & Sicherheit

### ✅ **Datenschutz-Features**
- **Keine personenbezogenen Daten** werden erfasst
- **Keine Tracker, Analytics oder Werbe-IDs**
- **Ausschließlich lokale Datenspeicherung** für PDF-Caching
- **Verschlüsselte HTTPS-Verbindungen** zum Schulserver
- **Keine Datenweiterleitung** an Dritte

### � **Sicherheitsmaßnahmen**
- **HTTP Basic Authentication** für Server-Zugriff
- **Certificate Pinning** für HTTPS-Verbindungen
- **Lokale Schlüsselspeicherung** mit Android Keystore
- **Network Security Configuration** für sichere Verbindungen

📄 [**Vollständige Datenschutzerklärung**](https://luka-loehr.github.io/LGKA/privacy.html)  
📄 [**Impressum**](https://luka-loehr.github.io/LGKA/impressum.html)

---

## 🧩 Architektur-Details

### 🏛️ **Design Patterns**
- **Repository Pattern** für Datenmanagement
- **Provider Pattern** mit Riverpod für State Management
- **Service Locator** für Dependency Injection
- **Observer Pattern** für UI-Updates

### 🔄 **State Management Flow**
```
PreferencesManager ↔ Riverpod Providers ↔ UI Screens
         ↓                    ↓               ↓
   SharedPreferences     PdfRepository    Material3 UI
```

### 🌐 **Netzwerk-Architektur**
```
Flutter App → HTTP Client → Basic Auth → School Server
     ↓              ↓           ↓            ↓
PDF Repository → Local Cache → File System → PDF Viewer
```

---

## � Entwicklung

### 🧪 **Testing**
```bash
# Unit Tests ausführen
flutter test

# Widget Tests
flutter test test/widget_test.dart

# Integration Tests (Device erforderlich)
flutter test integration_test/
```

### 🐛 **Debugging**
```bash
# Debug Mode mit Hot Reload
flutter run --debug

# Performance Profiling
flutter run --profile

# Release Testing
flutter run --release
```

### 📊 **Code-Qualität**
- **Flutter Lints** für Code-Standards
- **Analysis Options** für erweiterte Prüfungen
- **Dart Formatter** für konsistente Formatierung

---

## 📦 Releases & Deployment

### 🚀 **Release-Workflow**
1. **Version** in `pubspec.yaml` erhöhen
2. **Changelog** erstellen und testen
3. **Split APKs** für Testing bauen
4. **App Bundle** für Store-Release erstellen  
5. **GitHub Release** mit Assets erstellen

### 📋 **Version Management**
- **Semantic Versioning** (MAJOR.MINOR.PATCH)
- **Build Numbers** für interne Versionierung
- **Automatische iOS/Android Synchronisation**

### 🏪 **Store-Konfiguration**
- **Google Play Console** für Android-Releases
- **App Store Connect** für iOS-Releases
- **Automatische APK-Optimierung** durch Stores

---

## 🤝 Entwicklungs-Guidelines

### 📝 **Code-Standards**
- **Flutter Linting Rules** befolgen
- **Konsistente Naming Conventions**
- **Ausführliche Dokumentation** in kritischen Bereichen
- **Error Handling** für alle externen Abhängigkeiten

### 🧩 **Contribution Guidelines**
- **Fork** des Repositories erstellen
- **Feature Branch** für neue Funktionen
- **Pull Request** mit ausführlicher Beschreibung
- **Code Review** vor dem Merge

### 🐛 **Issue Reporting**
- **Bug Reports** mit Schritten zur Reproduktion
- **Feature Requests** mit detaillierter Beschreibung
- **Screenshots/Videos** bei UI-bezogenen Issues

---

## 📊 Projekt-Status

| Komponente | Status | Beschreibung |
|------------|--------|--------------|
| **Core App** | ✅ Produktiv | Alle Grundfunktionen implementiert |
| **PDF Integration** | ✅ Produktiv | Vollständig funktional |
| **Network Layer** | ✅ Produktiv | Mit Auto-Retry Mechanismus |
| **UI/UX** | ✅ Produktiv | Material Design 3 implementiert |
| **iOS Support** | ✅ Produktiv | Vollständig kompatibel |
| **Android 15+** | ✅ Produktiv | Edge-to-Edge unterstützt |

### 📈 **Aktuelle Version**
- **Version**: 2.0.1 (Build 28)
- **Release Date**: Januar 2025
- **Flutter Version**: 3.8.0+
- **Target Platforms**: Android 5.0+, iOS 12.0+

---

## 📜 Lizenz & Rechtliches

### 📄 **Creative Commons BY-NC-ND 4.0**

**✅ Erlaubt:**
- Private und Bildungsnutzung
- Code-Studium und Lernen
- Beiträge via Pull Requests
- Link-Sharing des Original-Repositories

**❌ Nicht erlaubt:**
- Kommerzielle Nutzung
- Veränderungen und Weiterverbreitung
- Eigenständige Veröffentlichung
- Upload in App Stores durch Dritte

### ⚖️ **Rechtliche Hinweise**
- **Privates Schülerprojekt** von Luka Löhr
- **Keine offizielle Verbindung** zum Lessing-Gymnasium Karlsruhe
- **Nur der ursprüngliche Entwickler** darf offizielle Releases erstellen

📄 [**Vollständige Lizenz**](LICENSE)

---

## 🙋‍♂️ Support & Kontakt

### 📞 **Support-Kanäle**
- **GitHub Issues** für Bug Reports und Feature Requests
- **Discussions** für allgemeine Fragen
- **E-Mail** für private Anfragen

### 🛠️ **Troubleshooting**
Häufige Probleme und Lösungen sind in den [**BUILD_NOTES.md**](BUILD_NOTES.md) dokumentiert.

### 📚 **Weiterführende Dokumentation**
- [**Build-Anleitung**](BUILD_NOTES.md) - Detaillierte Build-Instruktionen
- [**App-Konfiguration**](app_config/README.md) - Zentrale Konfigurationsverwaltung
- [**iOS Setup**](ios/README_APP_CONFIG.md) - iOS-spezifische Konfiguration

---

> **Entwickelt mit ❤️ von Luka Löhr für die Schulgemeinschaft des Lessing-Gymnasiums Karlsruhe.**

<div align="center">

[![Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Language-Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

</div>
