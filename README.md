# 📱 LGKA-App – Digitaler Vertretungsplan des Lessing-Gymnasiums Karlsruhe

> 🛠️ **Neu in Version 2.0.0**
> 
> - ✨ **Neues App-Icon** im modernen Look
> - 📅 **Datumsauswahl-Funktion** in den Einstellungen
> - 📄 **PDF-Viewer-Konfiguration**: intern oder extern anzeigen
> - ⚡ Verbesserte Ladeanimation beim App-Start
> - 🌐 Intelligentere Netzwerkerkennung mit Feedback

---

## 🧩 Funktionen

### 📆 Vertretungsplan-Anzeige
- Anzeige für **heute und morgen**
- Automatischer Download vom Schulserver
- 🔒 HTTP Basic Authentication
- 📂 Offline-Verfügbarkeit durch lokales Caching

### 📄 PDF-Integration
- Integrierter PDF-Viewer *(standardmäßig aktiviert)*
- Option zum Öffnen in externen Apps *(Google Drive, etc.)*
- ✉️ **PDF-Sharing-Funktion**
- 🔍 Zoom- & Scroll-Support

### 🎨 Benutzeroberfläche
- 🌙 Dark Mode Design
- 🎹 Adaptive Keyboard-Animation
- ⚙️ Erweiterte Einstellungen mit:
  - Datumsauswahl (heute, morgen oder benutzerdefiniert)
  - Internem/externem PDF-Viewer
- 👋 Willkommensbildschirm beim ersten Start

### 🚀 Weitere Features
- 🧠 Intelligente PDF-Metadaten-Extraktion (Datum, Uhrzeit, Wochentage)
- 🌐 Automatische Netzwerkerkennung & Statusanzeige
- 📳 Haptisches Feedback
- ⭐ In-App-Review-System

---

## 🔧 Technische Details

### 🧱 Frameworks
- Flutter SDK (≥ 3.8.0)
- Dart SDK (3.8.1)
- Material Design 3

### 📦 Haupt-Abhängigkeiten
- `riverpod` – State Management
- `go_router` – Navigation
- `http` – Netzwerkkommunikation
- `syncfusion_flutter_pdf` & `pdfx` – PDF-Anzeige
- `connectivity_plus` – Netzwerkstatus
- `share_plus` – PDF-Sharing

### ⚡ Performance-Optimierungen
- 📦 ABI-Split APKs (~9.6 MB pro Architektur)
- 🧹 R8 Full Mode & Resource Shrinking
- 🧵 Hintergrund-Isolate für PDF-Verarbeitung
- 🧠 Smartes Caching & Laderoutinen

---

## 🛠️ Installation & Entwicklung

### 📋 Voraussetzungen
```bash
Flutter SDK >= 3.8.0
Dart SDK >= 3.8.0
```

### 🚀 Setup
```bash
git clone https://github.com/luka-loehr/LGKA.git
cd LGKA
flutter pub get
flutter run
```

### 📦 Build
```bash
# Split APKs für minimale App-Größe
flutter build apk --release --split-per-abi

# Beispiel: Installation via ADB
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

📄 Weitere Details: [BUILD_NOTES.md](BUILD_NOTES.md)

---

## 🔐 Datenschutz

- ✅ Keine personenbezogenen Daten
- 🚫 Keine Tracker, Werbe-IDs oder Analytics
- 💾 Lokale Speicherung ausschließlich für PDF-Dateien
- 🔐 Nur verschlüsselte HTTPS-Verbindungen zum Schulserver
- 👥 Keine Weitergabe an Dritte

📄 [Vollständige Datenschutzerklärung](https://luka-loehr.github.io/LGKA/privacy.html)  
📄 [Impressum](https://luka-loehr.github.io/LGKA/impressum.html)

---

## 📦 Status

- **Version**: 2.0.0 (Build 27)
- 🧪 *Privates Schülerprojekt von Luka Löhr*
- 📍 *Keine offizielle Verbindung zum Lessing-Gymnasium Karlsruhe*

---

## 📜 Lizenz

**Creative Commons BY-NC-ND 4.0**

- ✅ Private & Bildungsnutzung erlaubt
- ❌ Kommerzielle Nutzung untersagt
- ❌ Veränderungen & Weiterverbreitung verboten

📄 [Vollständige Lizenz anzeigen](LICENSE)

---

> Entwickelt mit ❤️ von Luka Löhr für die Schulgemeinschaft des Lessing-Gymnasiums Karlsruhe.
