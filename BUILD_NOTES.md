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

**Für offizielle App-Downloads**: Nutze die offiziellen Kanäle oder kontaktiere den Entwickler.

---

## 🎯 Optimized for Small Size

This Flutter app is automatically configured to produce small APKs perfect for school devices with limited storage.

### ✅ **Automatic Optimizations Active:**
- **Icon Tree-Shaking**: 99%+ font size reduction
- **R8 Full Mode**: Aggressive code optimization
- **Resource Shrinking**: Removes unused resources
- **ProGuard Rules**: Dead code elimination
- **No Debug Symbols**: Excluded from production builds

### 📋 Build-Konfiguration

Die App ist permanent optimiert durch:
- **gradle.properties**: Universal optimizations (R8, tree-shaking, resource optimization)
- **build.gradle.kts**: Standard Flutter configuration with size optimizations
- **proguard-rules.pro**: Essential ProGuard rules for smaller builds
- **Keine Debug-Symbole**: Automatisch ausgeschlossen für kleinere Builds

**Ergebnis**: Jeder Standard-Flutter-Build ist automatisch für Schulgeräte optimiert! 🎉 

### 📱 **Standard Build Commands (Already Optimized):**

```bash
# Small APKs for direct distribution (9-10MB each)
flutter build apk --release --split-per-abi

# App Bundle for Google Play Store (~45MB, optimized by Play Store)
flutter build appbundle --release

# For iOS (also optimized automatically)
flutter build ios --release
```

### 📊 **Current Optimized Sizes:**
- **ARM64 APK**: ~9.8MB (perfect for school phones)
- **ARMv7 APK**: ~9.4MB (older school devices)
- **App Bundle**: ~45MB (Play Store delivers ~10MB to users)

### 🎒 **Perfect for School Kids:**
- **No special commands needed** - standard Flutter builds are optimized
- **Works for both Android and iOS** with same codebase
- **Easy to maintain** - no platform-specific configurations
- **Consistent small sizes** every time you build

## Zukünftige Builds

**Für offizielle Releases (nur Luka Löhr)**:
```bash
# Standard optimized builds
flutter build appbundle --release --build-name=X.Y.Z --build-number=N
flutter build apk --release --split-per-abi --build-name=X.Y.Z --build-number=N
```

**Für Entwickler**: Lokale Builds mit denselben Befehlen möglich, aber nicht zur Veröffentlichung berechtigt. 