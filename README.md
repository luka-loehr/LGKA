# LGKA-App – Digitaler Vertretungsplan des Lessing-Gymnasiums Karlsruhe

> **App-Größe**: Optimiert auf ~9.6MB (ursprünglich 130MB)

Eine Flutter-App zur digitalen Anzeige des Vertretungsplans des Lessing-Gymnasiums Karlsruhe. Entwickelt von Luka Löhr als nicht-kommerzielles Schulprojekt.

## Funktionen

**Vertretungsplan-Anzeige**
- Anzeige für heute und morgen
- Automatischer Download vom Schulserver
- HTTP Basic Authentication
- Offline-Verfügbarkeit durch lokales Caching

**PDF-Integration**
- Integrierter PDF-Viewer (standardmäßig aktiviert)
- Optional: Öffnen mit externen Apps (Google Drive, etc.)
- PDF-Sharing-Funktion
- Zoom- und Scroll-Funktionen

**Benutzeroberfläche**
- Dark Mode Design
- Adaptive Keyboard-Animation
- Erweiterte Einstellungen mit Datumsanzeige-Option und PDF-Viewer-Konfiguration
- Willkommensbildschirm beim ersten Start

**Weitere Features**
- Intelligente PDF-Metadaten-Extraktion (Datum, Uhrzeit, Wochentage)
- Automatische Netzwerkerkennung
- Haptisches Feedback
- In-App-Review-System

## Technische Details

**Frameworks**
- Flutter SDK (≥ 3.8.0)
- Dart SDK (3.8.1)
- Material Design 3

**Hauptabhängigkeiten**
- Riverpod (State Management)
- Go Router (Navigation)
- HTTP (Serververbindung)
- Syncfusion Flutter PDF & PDFx (PDF-Verarbeitung)
- Connectivity Plus (Netzwerkstatus)
- Share Plus (PDF-Sharing)

**Performance-Optimierungen**
- ABI-Split APKs (~9.6MB pro Architektur)
- R8 Full Mode und Resource Shrinking
- Hintergrund-Isolate für PDF-Verarbeitung
- Intelligentes Caching

## Installation & Entwicklung

### Voraussetzungen
```bash
Flutter SDK >= 3.8.0
Dart SDK >= 3.8.0
```

### Setup
```bash
git clone https://github.com/luka-loehr/LGKA.git
cd LGKA
flutter pub get
flutter run
```

### Build
```bash
# Split APKs für optimale Größe
flutter build apk --release --split-per-abi

# Installation
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Detaillierte Build-Anleitung: [BUILD_NOTES.md](BUILD_NOTES.md)

## Datenschutz

- Keine personenbezogenen Daten gespeichert
- Keine Tracker oder Werbe-IDs
- Lokale Datenspeicherung nur für PDFs
- HTTPS-Verbindung zum Schulserver
- Keine Datenübertragung an Drittanbieter

[Vollständige Datenschutzerklärung](https://luka-loehr.github.io/LGKA/privacy.html)

## Status

**Aktuelle Version**: 1.6.4 (Build 21)

Dieses Projekt ist ein Freizeitprojekt und steht in keinerlei offiziellem Zusammenhang mit dem Lessing-Gymnasium Karlsruhe.

## Lizenz

Creative Commons BY-NC-ND 4.0 Lizenz

- ✅ Nutzung für private und bildende Zwecke
- ❌ Kommerzielle Nutzung nicht gestattet
- ❌ Veränderung und Weiterverbreitung nicht erlaubt

[Vollständige Lizenz](LICENSE)

---

Entwickelt von Luka Löhr für die Schulgemeinschaft des Lessing-Gymnasiums Karlsruhe
