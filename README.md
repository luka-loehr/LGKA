# 📱 LGKA+ – Digitaler Vertretungsplan für das Lessing-Gymnasium Karlsruhe

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.8.0+-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.8.1+-0175C2?style=flat&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=flat)
![Version](https://img.shields.io/badge/Version-2.0.1-blue?style=flat)
![License](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-orange?style=flat)

**🎓 Moderne Flutter-App für den digitalen Vertretungsplan des Lessing-Gymnasiums Karlsruhe**

*Eine elegante, benutzerfreundliche Lösung für den schnellen Zugriff auf aktuelle Vertretungspläne*

[📥 Download](https://github.com/luka-loehr/LGKA/releases) • [📖 Dokumentation](#-installation--entwicklung) • [🐛 Issues](https://github.com/luka-loehr/LGKA/issues) • [💬 Discussions](https://github.com/luka-loehr/LGKA/discussions)

</div>

---

## 📋 Inhaltsverzeichnis

- [✨ Features](#-features-im-überblick)
- [🏗️ Technische Architektur](#️-technische-architektur)
- [🚀 Installation & Entwicklung](#-installation--entwicklung)
- [📱 Platform-Features](#-platform-spezifische-features)
- [🔐 Datenschutz & Sicherheit](#-datenschutz--sicherheit)
- [🧩 Architektur-Details](#-architektur-details)
- [🛠️ Entwicklung](#-entwicklung)
- [📦 Releases & Deployment](#-releases--deployment)
- [🤝 Entwicklungs-Guidelines](#-entwicklungs-guidelines)
- [📊 Projekt-Status](#-projekt-status)
- [📜 Lizenz & Rechtliches](#-lizenz--rechtliches)
- [🙋‍♂️ Support & Kontakt](#️-support--kontakt)

---

## 🌟 Über das Projekt

**LGKA+** ist eine moderne, plattformübergreifende Mobile App, die speziell für die Schulgemeinschaft des Lessing-Gymnasiums Karlsruhe entwickelt wurde. Die App bietet einen schnellen, zuverlässigen Zugriff auf die aktuellen Vertretungspläne mit einer intuitiven Benutzeroberfläche und umfassenden Offline-Funktionen.

### 🎯 **Projektziele**
- **📱 Benutzerfreundlichkeit**: Intuitive Navigation und schneller Zugriff auf Informationen
- **⚡ Performance**: Optimierte Ladezeiten und effiziente Datennutzung  
- **🔒 Datenschutz**: Vollständig datenschutzkonform ohne Tracking oder Datensammlung
- **🌍 Zugänglichkeit**: Offline-Verfügbarkeit und plattformübergreifende Kompatibilität
- **🔧 Wartbarkeit**: Saubere Architektur und umfassende Dokumentation

### 🏆 **Alleinstellungsmerkmale**
- **Zero-Tracking Policy**: Keine Datensammlung oder Analytics
- **Intelligent Caching**: Automatische Offline-Verfügbarkeit
- **Material Design 3**: Moderne, konsistente Benutzeroberfläche
- **Cross-Platform**: Native Performance auf Android und iOS
- **Open Source**: Transparente Entwicklung und Community-Beiträge

---

## ✨ Features im Überblick

### 🔄 **Intelligenter Vertretungsplan**
- **🔄 Automatischer Download** für heute und morgen
- **💾 Offline-Verfügbarkeit** durch smartes PDF-Caching 
- **📅 Wochentag-basierte Dateiverwaltung** (z.B. `montag.pdf`, `dienstag.pdf`)
- **🔐 Sichere Serververbindung** mit verschlüsselter Datenübertragung
- **📋 Metadaten-Extraktion** aus PDFs (Datum, Uhrzeit, Wochentag)
- **⚡ Intelligente Updates** nur bei Änderungen

### 📄 **PDF-Integration**
- **🔍 Integrierter PDF-Viewer** mit Zoom & Scroll-Support
- **🔗 Externe App-Integration** (Adobe Reader, Google Drive, etc.)
- **📤 PDF-Sharing-Funktion** für einfache Weiterleitung
- **⚙️ Background-Verarbeitung** für optimale Performance
- **🎯 Adaptive Anzeige** für verschiedene Bildschirmgrößen

### 🎨 **Benutzeroberfläche**
- **🎭 Material Design 3** mit konsistentem Dark Mode
- **📱 Edge-to-Edge Display** (Android 15+ kompatibel)
- **⌨️ Adaptive Keyboard-Animation** für optimale UX
- **🌊 Flüssige Navigation** mit benutzerdefinierten Animationen
- **📳 Haptisches Feedback** für bessere Interaktion
- **🌙 Automatischer Dark/Light Mode** basierend auf Systemeinstellungen

### ⚙️ **Erweiterte Einstellungen**
- **📅 Flexible Datumsauswahl** (heute, morgen, benutzerdefiniert)
- **👀 PDF-Viewer-Konfiguration** (intern/extern)
- **🔧 Personalisierung** von App-Verhalten und Aussehen
- **ℹ️ App-Informationen** und Rechtliche Hinweise
- **🔄 Automatische Updates** der Konfiguration

### 🌐 **Intelligente Netzwerkverwaltung**
- **📡 Automatische Verbindungserkennung** 
- **🔄 Exponentielles Auto-Retry** bei Verbindungsproblemen
- **🐌 Slow-Connection-Detection** mit Nutzer-Feedback
- **📴 Offline-First Architektur** für zuverlässige Verfügbarkeit
- **🛡️ Robuste Error-Behandlung** mit aussagekräftigen Meldungen

### 🎁 **Zusätzliche Features**
- **👋 Willkommensbildschirm** beim ersten Start mit App-Tour
- **⭐ In-App-Review-System** für direktes Nutzerfeedback
- **🎨 Adaptive App-Icons** für Android und iOS
- **🛡️ Umfassende Error-Behandlung** mit nutzerfreundlichen Meldungen
- **🔔 Smart Notifications** bei verfügbaren Updates
- **📊 Performance-Monitoring** für optimale App-Geschwindigkeit

---

## 🏗️ Technische Architektur

### 🎯 **Technology Stack**
| Kategorie | Technologie | Version | Zweck |
|-----------|------------|---------|--------|
| **Frontend** | Flutter SDK | 3.8.0+ | Cross-Platform UI Framework |
| **Language** | Dart | 3.8.1+ | Programmiersprache |
| **Design** | Material Design 3 | - | UI/UX Design System |
| **State Management** | Riverpod | 2.6.1 | Reaktive State-Verwaltung |
| **Navigation** | go_router | 15.1.2 | Deklarative Navigation |
| **Networking** | HTTP Client | 1.2.2 | Netzwerkkommunikation |

### 🎯 **Framework & Sprachen**
- **🔷 Flutter SDK**: 3.8.0+ (Dart 3.8.1+) - Cross-Platform Development
- **🎨 Material Design 3** mit Custom Dark Theme und adaptiven Komponenten
- **🤖 Kotlin** für Android-spezifische Implementierungen und native Features
- **🍎 Swift** für iOS-Konfiguration und plattformspezifische Optimierungen

### 🗂️ **Projektstruktur**
```
lib/
├── 🖥️  screens/          # 6 Haupt-Screens (Welcome, Auth, Home, etc.)
├── 🔧  services/         # File-Opener & Review-Service
├── 📊  providers/        # Riverpod State Management & Haptic Service
├── 🧭  navigation/       # go_router Navigation mit Animationen
├── 💾  data/            # PDF Repository & Preferences Manager
└── 🎨  theme/           # Custom Material Design 3 Theme

assets/
├── 🖼️  images/          # App-Icons, Logos und UI-Grafiken
└── 📄  configs/         # Konfigurationsdateien

android/                 # Android-spezifische Implementierung
ios/                     # iOS-spezifische Konfiguration
```

### 📦 **Haupt-Dependencies**
| Package | Version | Zweck | Kategorie |
|---------|---------|--------|-----------|
| `flutter_riverpod` | ^2.6.1 | Reaktive State-Verwaltung | 🔄 State Management |
| `go_router` | ^15.1.2 | Deklarative Navigation & Routing | 🧭 Navigation |
| `http` | ^1.2.2 | Sichere Netzwerkkommunikation | 🌐 Network |
| `syncfusion_flutter_pdf` | ^29.2.9 | PDF-Verarbeitung & Analyse | 📄 Document Processing |
| `pdfx` | ^2.9.1 | Hochperformante PDF-Anzeige | 🔍 PDF Viewer |
| `connectivity_plus` | ^6.1.0 | Intelligente Netzwerküberwachung | 📡 Connectivity |
| `share_plus` | ^11.0.0 | Plattformübergreifendes PDF-Sharing | 📤 Sharing |
| `shared_preferences` | ^2.3.4 | Sichere lokale Datenspeicherung | 💾 Storage |
| `in_app_review` | ^2.0.10 | Natives Review-System | ⭐ User Experience |
| `url_launcher` | ^6.3.2 | Externe App-Integration | 🔗 External Apps |

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

## 🚀 Installation & Entwicklung

### 🔽 **Download & Installation**

#### **📱 Für Endnutzer**
- **[🔽 Latest Release](https://github.com/luka-loehr/LGKA/releases/latest)** - Neueste stabile Version
- **[📋 Alle Releases](https://github.com/luka-loehr/LGKA/releases)** - Vollständige Versionshistorie
- **[📖 Installationsanleitung](https://github.com/luka-loehr/LGKA/wiki/Installation)** - Schritt-für-Schritt Guide

#### **🛠️ Für Entwickler**
- **[📂 Repository](https://github.com/luka-loehr/LGKA)** - Vollständiger Quellcode
- **[🐛 Bug Reports](https://github.com/luka-loehr/LGKA/issues)** - Fehler melden
- **[💡 Feature Requests](https://github.com/luka-loehr/LGKA/discussions)** - Neue Funktionen vorschlagen
- **[📊 Project Board](https://github.com/luka-loehr/LGKA/projects)** - Entwicklungsfortschritt

### 📋 **Voraussetzungen**
```bash
# Entwicklungsumgebung
Flutter SDK >= 3.8.0     # Cross-Platform Framework
Dart SDK >= 3.8.1        # Programmiersprache
Android SDK >= 21        # Android 5.0+
iOS >= 12.0              # iOS Deployment Target

# Zusätzliche Tools
Git >= 2.20             # Versionskontrolle
Android Studio / VS Code # IDE mit Flutter-Plugin
```

### 🚀 **Schnellstart**
```bash
# 1. Repository klonen
git clone https://github.com/luka-loehr/LGKA.git
cd LGKA

# 2. Dependencies installieren
flutter pub get

# 3. App-Icons generieren
dart run generate_app_icons.dart

# 4. Development Server starten
flutter run --debug
```

### 🏗️ **Build-Kommandos**

#### **⚡ Development Builds (Schnelle Iteration)**
```bash
# ARM64 APK für moderne Android-Geräte (~9.9MB)
flutter build apk --release --target-platform=android-arm64

# Installation via ADB
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

#### **🏪 Production Builds (Store-Ready)**
```bash
# Google Play Store (App Bundle)
flutter build appbundle --release

# Apple App Store (iOS)
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
- **🚫 Zero-Tracking Policy**: Keine personenbezogenen Daten werden erfasst
- **📵 Keine Analytics oder Werbe-IDs**: Vollständig werbefrei und tracking-frei
- **💾 Ausschließlich lokale Datenspeicherung** für PDF-Caching
- **🔒 End-to-End Verschlüsselung** für alle Serververbindungen
- **🛡️ Privacy by Design**: Datenschutz als Grundprinzip der Architektur
- **🌍 DSGVO-konform**: Vollständige Einhaltung europäischer Datenschutzstandards

### 🛠️ **Sicherheitsmaßnahmen**
- **🔐 Sichere Authentifizierung** für Serverzugriff
- **📜 Certificate Pinning** für HTTPS-Verbindungen
- **🔑 Android Keystore Integration** für sichere Schlüsselspeicherung
- **🌐 Network Security Configuration** für geschützte Verbindungen
- **🔍 Code Obfuscation** in Release-Builds
- **⚡ Secure by Default**: Alle Verbindungen standardmäßig verschlüsselt

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

## 🛠️ Entwicklung

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

### 🆘 **Hilfe & Support**

| Problem | Lösung | Link |
|---------|---------|------|
| **🐛 Bug gefunden** | GitHub Issues | [Fehler melden](https://github.com/luka-loehr/LGKA/issues/new) |
| **💡 Feature-Idee** | GitHub Discussions | [Diskussion starten](https://github.com/luka-loehr/LGKA/discussions) |
| **❓ Allgemeine Fragen** | Wiki & FAQ | [Dokumentation](https://github.com/luka-loehr/LGKA/wiki) |
| **🔧 Build-Probleme** | Build-Anleitung | [BUILD_NOTES.md](BUILD_NOTES.md) |
| **⚙️ Konfiguration** | Setup-Guide | [App-Konfiguration](app_config/README.md) |

### 📚 **Wichtige Ressourcen**

#### **📖 Dokumentation**
- **[📘 Haupt-Dokumentation](https://github.com/luka-loehr/LGKA/wiki)** - Vollständige Anleitung
- **[🔨 Build-Anleitung](BUILD_NOTES.md)** - Detaillierte Build-Instruktionen
- **[⚙️ App-Konfiguration](app_config/README.md)** - Zentrale Konfigurationsverwaltung
- **[🍎 iOS Setup](ios/README_APP_CONFIG.md)** - iOS-spezifische Konfiguration
- **[🎨 Icon-System](assets/images/app-icons/README.md)** - App-Icon Verwaltung

#### **🌐 Online-Ressourcen**
- **[🏠 GitHub Pages](https://luka-loehr.github.io/LGKA/)** - Projektwebsite
- **[🔒 Datenschutz](https://luka-loehr.github.io/LGKA/privacy.html)** - Vollständige Datenschutzerklärung
- **[⚖️ Impressum](https://luka-loehr.github.io/LGKA/impressum.html)** - Rechtliche Informationen
- **[📜 Lizenz](LICENSE)** - Creative Commons BY-NC-ND 4.0

### 🛠️ **Troubleshooting**
Häufige Probleme und Lösungen sind detailliert in den [**BUILD_NOTES.md**](BUILD_NOTES.md) dokumentiert.

### 📧 **Direkter Kontakt**
Für private Anfragen oder spezielle Anliegen können Sie den Entwickler direkt über die GitHub-Profilseite kontaktieren.

---

<div align="center">

## 📊 Projekt-Statistiken

![GitHub stars](https://img.shields.io/github/stars/luka-loehr/LGKA?style=social)
![GitHub forks](https://img.shields.io/github/forks/luka-loehr/LGKA?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/luka-loehr/LGKA?style=social)

![GitHub release](https://img.shields.io/github/v/release/luka-loehr/LGKA?include_prereleases&sort=semver)
![GitHub release date](https://img.shields.io/github/release-date/luka-loehr/LGKA)
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/luka-loehr/LGKA)

</div>

---

> **💡 Entwickelt mit Leidenschaft und ❤️ von [Luka Löhr](https://github.com/luka-loehr) für die Schulgemeinschaft des Lessing-Gymnasiums Karlsruhe.**  
> *Ein privates Schülerprojekt, das Digitalisierung und Benutzerfreundlichkeit vereint.*

<div align="center">

### 🚀 **Powered by Modern Technology**

[![Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Language-Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Material Design](https://img.shields.io/badge/Design-Material%203-757575?style=for-the-badge&logo=material-design&logoColor=white)](https://m3.material.io)

### 🛡️ **Quality Assurance**

![Code Quality](https://img.shields.io/badge/Code%20Quality-A+-brightgreen?style=flat&logo=codeclimate)
![Maintenance](https://img.shields.io/badge/Maintenance-Active-brightgreen?style=flat)
![Documentation](https://img.shields.io/badge/Documentation-Excellent-brightgreen?style=flat&logo=gitbook)

### 🌟 **Community & Support**

[![GitHub Issues](https://img.shields.io/github/issues/luka-loehr/LGKA?style=flat&logo=github)](https://github.com/luka-loehr/LGKA/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/luka-loehr/LGKA?style=flat&logo=github)](https://github.com/luka-loehr/LGKA/pulls)
[![License](https://img.shields.io/github/license/luka-loehr/LGKA?style=flat)](LICENSE)

---

**🔗 Schnellzugriff:** 
[Website](https://luka-loehr.github.io/LGKA/) • 
[Releases](https://github.com/luka-loehr/LGKA/releases) • 
[Wiki](https://github.com/luka-loehr/LGKA/wiki) • 
[Diskussionen](https://github.com/luka-loehr/LGKA/discussions)

---

*© 2025 Luka Löhr. Dieses Projekt steht unter der [Creative Commons BY-NC-ND 4.0](LICENSE) Lizenz.*

</div>
