# LGKA Flutter App - Build-Anleitung

## ⚠️ Wichtige Lizenz-Hinweise

**ACHTUNG**: Diese Anleitung dient nur zu **Bildungs- und Entwicklungszwecken**!

🚫 **Was NICHT erlaubt ist:**
- Erstellen und Veröffentlichen eigener App-Versionen
- Upload von selbst erstellten Builds in App Stores
- Kommerzielle Nutzung der App
- Verbreitung modifizierter Versionen
- Eigenständige Veröffentlichung unter anderem Namen

✅ **Was erlaubt ist:**
- Code studieren und verstehen
- Lokale Entwicklungsbuilds zum Lernen
- Beitrag zu diesem Projekt via Pull Requests
- Teilen des ursprünglichen Repository-Links

Diese App steht unter der **Creative Commons BY-NC-ND 4.0 Lizenz**. Nur der ursprüngliche Entwickler (Luka Löhr) darf offizielle Releases erstellen und veröffentlichen.

---

## 🏗️ Build-Konfiguration

### Automatische Optimierungen
- **R8 Full Mode**: Aktiviert in `gradle.properties`
- **Resource Shrinking**: Entfernt ungenutzte Ressourcen
- **ProGuard**: Dead-Code-Eliminierung
- **Icon Tree-Shaking**: 99%+ Schriftarten-Reduzierung
- **Keine Debug-Symbole**: Für kleinere APK-Größen

### Konfigurationsdateien
- `android/gradle.properties`: R8, Tree-Shaking, Ressourcen-Optimierung
- `android/app/build.gradle.kts`: Standard Flutter-Konfiguration
- `android/app/proguard-rules.pro`: ProGuard-Regeln

## 📱 Production Builds (App Stores)

### Google Play Store
```bash
flutter build appbundle --release
```
- **Output**: `build/app/outputs/bundle/release/app-release.aab`
- **Größe**: ~45MB (Play Store optimiert auf ~9MB für Endnutzer)
- **Verwendung**: Offizielle Releases im Google Play Store

### Apple App Store
```bash
flutter build ios --release
```
- **Output**: iOS App für App Store Connect
- **Verwendung**: Offizielle Releases im Apple App Store

## 🔧 Development Builds (Testing)

### Split APKs für lokales Testing
```bash
flutter build apk --release --split-per-abi
```

**Output-Dateien:**
- `app-arm64-v8a-release.apk` (~9.9MB)
- `app-armeabi-v7a-release.apk` (~9.5MB)  
- `app-x86_64-release.apk` (~10.0MB)

**Verwendung:**
- Lokales Testing auf Entwicklungsgeräten
- Debugging ohne App Store Upload
- Schnelle Installation via ADB

### Installation auf Testgerät
```bash
# Gerät-ABI ermitteln
adb shell getprop ro.product.cpu.abi

# Passende APK installieren
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## 📊 Build-Größen

| Build-Typ | Größe | Verwendung |
|-----------|-------|------------|
| App Bundle | ~45MB | Google Play Store |
| ARM64 APK | ~9.9MB | Development/Testing |
| ARMv7 APK | ~9.5MB | Development/Testing |
| x86_64 APK | ~10.0MB | Emulator/Testing |

## 🚀 Release-Workflow

### 1. Development Testing
```bash
# Lokale Tests mit Split APKs
flutter build apk --release --split-per-abi
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### 2. Production Release
```bash
# Google Play Store
flutter build appbundle --release

# Apple App Store  
flutter build ios --release
```

### 3. Version Management
```bash
# Mit spezifischer Version (nur für offizielle Releases)
flutter build appbundle --release --build-name=1.5.5 --build-number=18
```

## 🔍 Troubleshooting

### APK Installation fehlgeschlagen
```bash
# Alte Version entfernen
adb uninstall com.lgka

# Neue Version installieren
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Falsche ABI-Architektur
```bash
# Gerät-ABI prüfen
adb shell getprop ro.product.cpu.abi

# Verfügbare APKs anzeigen
ls -la build/app/outputs/flutter-apk/
```

### Build-Größe zu groß
- **Problem**: Universal APK statt Split APK erstellt
- **Lösung**: `--split-per-abi` Flag verwenden
- **Nicht verwenden**: `flutter build apk --release` (erstellt Universal APK ~30MB)

## 📋 Entwicklungsumgebung

### Voraussetzungen
- Flutter SDK ≥ 3.8.0
- Android SDK mit Build Tools
- Xcode (für iOS Builds)

### Setup
```bash
git clone https://github.com/luka-loehr/LGKA.git
cd LGKA
flutter pub get
```

---

**Nur offizielle Releases durch Luka Löhr. Entwickler können lokale Builds für Lernzwecke erstellen.** 