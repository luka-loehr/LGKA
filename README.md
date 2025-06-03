# LGKA-App – Vertretungsplan Lessing-Gymnasium Karlsruhe

Eine Flutter-App für digitale Vertretungspläne mit Anmeldung, Offline-Verfügbarkeit und modernem Dark-Theme-Design.

Eine moderne Flutter-App zur Anzeige des Vertretungsplans des Lessing-Gymnasiums Karlsruhe. Entwickelt von Luka Löhr als nicht-kommerzielles Schulprojekt.

## 📉 Funktionen

- Anzeige des Vertretungsplans für heute & morgen
- PDF-Download direkt vom Schulserver
- Lokale Zwischenspeicherung der Datei zur Offline-Nutzung
- Dark Mode
- Haptisches Feedback
- Willkommensbildschirm beim ersten Start
- Metadaten-Auswertung (Datum, Wochentag)

## 📊 Technisches

- Programmiert mit Flutter (ab Version 3.8.0)
- State-Management mit Riverpod
- Navigation via Go Router
- PDF-Verarbeitung mit `syncfusion_flutter_pdf`
- Netzwerk: `http`
- Dateiöffnung mit `open_filex`
- Systeminfos über `package_info_plus`
- Dateipfade via `path_provider`

## 🚀 Schnellstart

### Voraussetzungen

- Flutter SDK (>= 3.8.0)
- Dart SDK (stable)
- Android Studio oder VS Code mit Flutter-Plugins

### Installation

```bash
git clone https://github.com/luka-loehr/LGKA.git
cd LGKA
flutter pub get
flutter run
```

## 📦 Build-Anleitung

**⚠️ Lizenz-Hinweis**: Diese Build-Anleitung dient nur zu **Bildungs- und Entwicklungszwecken**. Aufgrund der CC BY-NC-ND 4.0 Lizenz dürfen keine eigenen App-Versionen erstellt und veröffentlicht werden. Nur der ursprüngliche Entwickler darf offizielle Releases erstellen.

Für die Erstellung von Release-Builds mit Debug-Symbolen für Google Play Console:

```bash
# Standard Release Build
flutter build appbundle --release --build-name=1.3.0 --build-number=N

# Empfohlener Build mit Debug-Symbolen und Code-Obfuskierung
flutter build appbundle --release --build-name=1.3.0 --build-number=N --split-debug-info=symbols --obfuscate
```

**📖 Detaillierte Build-Anleitung**: Siehe [BUILD_NOTES.md](BUILD_NOTES.md) für:
- Vollständige Konfiguration der Android-Build-Umgebung
- Lösung des Google Play Console Debug-Symbol-Warnings
- Upload-Anleitung für Debug-Symbole
- App-Optimierungen und ProGuard-Konfiguration
- Troubleshooting-Tipps

## 🔒 Datenschutz

Die App verarbeitet keine personenbezogenen Daten. Es werden keine Tracker, Cookies oder IDs verwendet. Die einzige Netzwerkverbindung dient dem Download der PDF-Datei vom Schulserver über HTTPS.

Ausführliche Informationen findest du in der [Datenschutzerklärung](https://luka-loehr.github.io/LGKA/privacy.html).

## 🌐 Status

Diese App ist ein reines Freizeitprojekt und steht in keinerlei offiziellem Zusammenhang mit dem Lessing-Gymnasium Karlsruhe.

## ⚖️ Lizenz

Dieses Projekt steht unter der **Creative Commons BY-NC-ND 4.0 Lizenz**. 
Es darf **nicht kommerziell genutzt**, **nicht verändert** und **nicht neu veröffentlicht** werden. 
Siehe [LICENSE](LICENSE) für Details.
