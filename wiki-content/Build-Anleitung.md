# 🏗️ Build-Anleitung

Diese Anleitung erklärt, wie du die LGKA+ App selbst kompilieren kannst.

## Schnell-Start

### Minimal-Setup

```bash
# Repository klonen
git clone https://github.com/luka-loehr/LGKA.git
cd LGKA

# Dependencies installieren
flutter pub get

# App-Icons generieren
dart run generate_app_icons.dart

# Debug-Build starten
flutter run --debug
```

## Build-Varianten

### Development Builds

**Debug-Build (mit Hot Reload):**
```bash
flutter run --debug
```

**Profile-Build (Performance-Testing):**
```bash
flutter run --profile
```

**Release-Build (lokal testen):**
```bash
flutter run --release
```

### Distribution Builds

**Android APK (ARM64 - empfohlen):**
```bash
flutter build apk --release --target-platform=android-arm64
```
- **Ausgabe:** `build/app/outputs/flutter-apk/app-release.apk`
- **Größe:** ~9 MB
- **Für:** Moderne Android-Geräte (2019+)

**Android APK (Universal - alle Architekturen):**
```bash
flutter build apk --release
```
- **Ausgabe:** `build/app/outputs/flutter-apk/app-release.apk`
- **Größe:** ~25 MB
- **Für:** Maximale Kompatibilität

**Android App Bundle (Play Store):**
```bash
flutter build appbundle --release
```
- **Ausgabe:** `build/app/outputs/bundle/release/app-release.aab`
- **Für:** Google Play Store Distribution

**iOS Build:**
```bash
flutter build ios --release
```
- **Ausgabe:** `build/ios/iphoneos/Runner.app`
- **Für:** App Store oder Enterprise Distribution

## Build-Konfiguration

### App-Konfiguration anpassen

**Zentrale Konfiguration** in `app_config/app_config.yaml`:

```yaml
app_name: "LGKA+"
app_description: "LGKA+ App - Digitaler Vertretungsplan"
package_name: "com.lgka"
version_name: "2.0.1"
version_code: "28"
```

**Konfiguration anwenden:**
```bash
dart run scripts/apply_app_config.dart
```

### App-Icons aktualisieren

**Icon-Datei ersetzen:**
- Neue PNG-Datei nach `assets/images/app-icons/app-logo.png`
- Auflösung: 1024×1024 Pixel empfohlen

**Icons generieren:**
```bash
dart run generate_app_icons.dart
```

Generiert automatisch alle benötigten Icon-Größen für Android und iOS.

## Build-Umgebung

### Android-Konfiguration

**Build-Gradle** (`android/app/build.gradle.kts`):
```kotlin
android {
    compileSdk = 34
    defaultConfig {
        minSdk = 21
        targetSdk = 34
    }
    
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(/* ... */)
        }
    }
}
```

**Signing-Konfiguration:**
- **Debug**: Automatisches Debug-Signing
- **Release**: Produktions-Keystore erforderlich

### iOS-Konfiguration

**App-Name zentral konfiguriert** in `ios/Runner/app_config.xcconfig`:
```
APP_DISPLAY_NAME = LGKA+
```

**Build-Einstellungen:**
- **Deployment Target**: iOS 12.0
- **Bundle ID**: `com.lgka`
- **Version**: Automatisch aus `pubspec.yaml`

## Installation & Testing

### Android-Installation

**Via ADB (empfohlen für Development):**
```bash
# APK installieren/updaten
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Mehrere Geräte - spezifisches Gerät wählen
adb devices
adb -s [DEVICE_ID] install -r app-release.apk
```

**Via Dateimanager:**
- APK-Datei auf Gerät kopieren
- "Unbekannte Quellen" in Einstellungen aktivieren
- APK antippen und installieren

### iOS-Installation

**Development:**
```bash
# Auf verbundenem iOS-Gerät installieren
flutter install --debug

# Simulator starten
open -a Simulator
flutter run
```

**Distribution:**
- Über Xcode Archive & Upload to App Store
- Oder Enterprise Distribution über MDM

## Build-Optimierungen

### Android-Optimierungen

**ProGuard-Konfiguration** (`android/app/proguard-rules.pro`):
```proguard
# Flutter-spezifische Optimierungen
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }

# PDF-Library spezifisch
-keep class com.syncfusion.** { *; }
```

**R8 Code Shrinking:**
- **Dead Code Elimination**: Entfernt ungenutzten Code
- **Resource Shrinking**: Entfernt ungenutzte Ressourcen
- **Icon Tree-Shaking**: Reduziert Font-Größe um 99%+

### Performance-Optimierungen

**Build-Flags:**
```bash
# Optimierter Release-Build
flutter build apk --release \
  --target-platform=android-arm64 \
  --optimize-size \
  --tree-shake-icons
```

**Dart-Optimierungen:**
- **Ahead-of-Time (AOT) Compilation** in Release-Builds
- **Dead Code Elimination** durch Tree-Shaking
- **Code Splitting** für minimale App-Größe

## Build-Größen & Performance

### Typische Build-Größen

| Build-Typ | Größe | Installiert | Verwendung |
|-----------|-------|-------------|------------|
| **Debug APK** | ~45 MB | ~80 MB | Development |
| **Release APK (ARM64)** | ~9 MB | ~23 MB | Distribution |
| **Release APK (Universal)** | ~25 MB | ~55 MB | Maximale Kompatibilität |
| **App Bundle** | ~15 MB | Variable | Google Play Store |

### Performance-Metriken

**Startup-Zeit:**
- **Cold Start**: <2 Sekunden
- **Warm Start**: <1 Sekunde
- **PDF-Öffnung**: <500ms (gecacht)

**Memory-Verbrauch:**
- **Basis-App**: ~30 MB RAM
- **Mit PDF geladen**: ~45 MB RAM
- **Peak bei PDF-Processing**: ~60 MB RAM

## Fehlerbehandlung

### Build-Fehler

**"Execution failed for task ':app:lintVitalRelease'":**
```bash
# Lint-Prüfungen bei Release überspringen
flutter build apk --release --no-tree-shake-icons
```

**"Android dependency conflict":**
```bash
# Dependencies bereinigen
flutter clean
flutter pub get
```

**"iOS build failed":**
```bash
# iOS Dependencies neu installieren
cd ios
rm Podfile.lock
rm -rf Pods/
pod install
cd ..
```

### Signing-Probleme

**Android Debug-Signing:**
- Automatisch mit Flutter Debug-Key
- SHA-1: `6C:61:44:44:D0:57:67:85:12:57:31:BA:05:5F:9D:41:87:63:A6:F3`

**Android Release-Signing:**
- Produktions-Keystore erforderlich
- SHA-1: `D9:40:04:B5:20:3B:B8:8D:85:30:4B:EE:CC:8D:C3:9D:48:92:F3:20`

### Performance-Debugging

**Performance-Analyse:**
```bash
# Performance-Profiling aktivieren
flutter run --profile --trace-startup
```

**Memory-Debugging:**
```bash
# Memory-Leaks analysieren
flutter run --debug --enable-dart-profiling
```

## CI/CD Integration

### GitHub Actions

**Beispiel-Workflow** (`.github/workflows/build.yml`):
```yaml
name: Build APK
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.8.0'
      - run: flutter pub get
      - run: dart run generate_app_icons.dart
      - run: flutter build apk --release --target-platform=android-arm64
```

### Automatisierte Tests

```bash
# Alle Tests ausführen
flutter test

# Coverage-Report generieren
flutter test --coverage
```

---

**Build-Support:** lgka.vertretungsplan@gmail.com