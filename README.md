# LGKA-App – Digitaler Vertretungsplan des Lessing-Gymnasiums Karlsruhe

> **🎉 Neueste Verbesserung**: Die App-Größe wurde drastisch von **130MB auf nur noch 9MB** reduziert! Das bedeutet schnellere Downloads und weniger Speicherplatzverbrauch.  

> **📱 Und neu in Version 1.5.5**: Jetzt auch verfügbar für **iOS** – erstmals nutzbar auf iPhones und iPads!

Eine moderne Flutter-App zur digitalen Anzeige des Vertretungsplans des Lessing-Gymnasiums Karlsruhe. Entwickelt von Luka Löhr als nicht-kommerzielles Schulprojekt für Schüler, Lehrer und Eltern.

## 🤔 Was macht diese App?

Die LGKA-App ist ein **digitaler Vertretungsplan-Viewer**, der es ermöglicht, die tagesaktuellen Stundenplanänderungen des Lessing-Gymnasiums Karlsruhe direkt auf dem Smartphone oder Tablet anzuzeigen. Die App lädt automatisch die offiziellen PDF-Vertretungspläne vom Schulserver herunter und stellt sie in einer benutzerfreundlichen Oberfläche dar.

### 🔑 Hauptfunktionen

**📅 Vertretungsplan-Anzeige**
- Anzeige des Vertretungsplans für **heute** und **morgen**
- Automatischer Download der aktuellen PDF-Dateien vom Schulserver
- Sichere Verbindung mit HTTP Basic Authentication
- Intelligente Dateibenennung basierend auf Wochentagen

**💾 Offline-Verfügbarkeit**
- Lokale Zwischenspeicherung aller heruntergeladenen PDFs
- Zugriff auf Vertretungspläne auch ohne Internetverbindung
- Automatische Erkennung von bereits gespeicherten Dateien
- Hintergrund-Preloading für bessere Performance

**📊 Intelligente Metadaten-Auswertung**
- Automatische Extraktion von Datum und Uhrzeit aus den PDFs
- Erkennung der Wochentage (Montag, Dienstag, etc.)
- Anzeige der letzten Aktualisierung für jeden Plan
- Optimierte Dateiverwaltung basierend auf Wochentagen

**🎨 Moderne Benutzeroberfläche**
- Elegantes **Dark Mode Design** für angenehme Nutzung
- **Haptisches Feedback** für bessere Benutzererfahrung
- Interaktiver **Willkommensbildschirm** beim ersten Start
- Responsive Design für verschiedene Bildschirmgrößen

**🔐 Benutzerauthentifizierung**
- Sichere Anmeldung mit Schulzugangsdaten
- Speicherung der Anmeldedaten für automatische Verbindung
- Schutz der Daten durch lokale Verschlüsselung

**📱 PDF-Integration**
- Nahtlose PDF-Anzeige mit der Syncfusion PDF-Bibliothek
- Zoom- und Scroll-Funktionen für bessere Lesbarkeit
- Möglichkeit zum Öffnen der PDFs in externen Apps
- Optimierte Darstellung für mobile Geräte

## 🤖 Technische Details

### Architektur & Frameworks
- **Flutter SDK** (ab Version 3.8.0) für plattformübergreifende Entwicklung
- **Dart SDK** (stable) als Programmiersprache
- **Material Design 3** für moderne UI-Komponenten

### State Management & Navigation
- **Riverpod** für reaktives State Management
- **Go Router** für deklarative Navigation
- Provider-basierte Architektur für sauberen Code

### Netzwerk & Datenverarbeitung
- **HTTP** für sichere Serververbindungen mit Basic Auth
- **Syncfusion Flutter PDF** für PDF-Verarbeitung und -Anzeige
- **Path Provider** für plattformspezifische Dateipfade
- **Shared Preferences** für lokale Datenspeicherung

### System-Integration
- **Package Info Plus** für App-Metadaten
- **Open File X** für externe PDF-Viewer-Integration
- **Permission Handler** für Dateizugriff-Berechtigungen
- **Flutter Launcher Icons** für App-Icon-Generierung

### Performance-Optimierungen
- **Hintergrund-Isolate** für PDF-Textextraktion ohne UI-Blockierung
- **Intelligentes Caching** mit weekday-basierter Dateibenennung
- **Preloading-Mechanismus** für schnelle App-Starts
- **Komprimierte Assets** für minimale App-Größe (nur noch 9MB!)

## 🚀 Installation & Entwicklung

### Voraussetzungen
```bash
Flutter SDK >= 3.8.0
Dart SDK (stable)
Android Studio oder VS Code mit Flutter-Plugins
```

### Schnellstart
```bash
git clone https://github.com/luka-loehr/LGKA.git
cd LGKA
flutter pub get
flutter run
```

### Build-Prozess
```bash
# Standard Release Build
flutter build appbundle --release --build-name=1.5.0 --build-number=15

# Optimierter Build mit Debug-Symbolen
flutter build appbundle --release --build-name=1.5.0 --build-number=15 --split-debug-info=symbols --obfuscate
```

**🔧 Detaillierte Build-Anleitung**: Siehe [BUILD_NOTES.md](BUILD_NOTES.md) für vollständige Konfiguration und Troubleshooting.

## 🛡️ Datenschutz & Sicherheit

Die LGKA-App wurde mit höchsten Datenschutzstandards entwickelt:

- **Keine personenbezogenen Daten** werden verarbeitet oder gespeichert
- **Keine Tracker, Cookies oder Werbe-IDs** vorhanden
- **Lokale Datenspeicherung** nur für Vertretungsplan-PDFs
- **HTTPS-verschlüsselte Verbindung** zum Schulserver
- **Keine Datenübertragung** an Drittanbieter

Vollständige Informationen in der [Datenschutzerklärung](https://luka-loehr.github.io/LGKA/privacy.html).

## 🎯 Zielgruppe

Diese App richtet sich an:
- **Schüler** des Lessing-Gymnasiums Karlsruhe
- **Lehrkräfte** für schnellen Zugriff auf Vertretungen
- **Eltern** zur Information über Stundenplanänderungen
- **Verwaltung** für mobile Vertretungsplan-Einsicht

## 🌟 Besonderheiten

### Warum diese App verwenden?
- **Extrem kompakt**: Nur 9MB statt der ursprünglich 130MB
- **Offline-fähig**: Funktioniert auch ohne Internet
- **Benutzerfreundlich**: Modernes Design mit Dark Mode
- **Zuverlässig**: Direkte Verbindung zum offiziellen Schulserver
- **Schnell**: Hintergrund-Preloading für sofortige Verfügbarkeit
- **Datenschutzkonform**: Keine unnötigen Berechtigungen oder Tracking

### Innovation & Technik
- Intelligente PDF-Metadaten-Extraktion
- Weekday-basierte Dateiverwaltung
- Isolate-basierte Verarbeitung für flüssige Performance
- Responsive Material Design 3 Oberfläche

## 🔧 Status & Entwicklung

**Aktuelle Version**: 1.5.0 (Build 15)

Diese App ist ein **reines Freizeitprojekt** und steht in keinerlei offiziellem Zusammenhang mit dem Lessing-Gymnasium Karlsruhe. Sie wurde von einem Schüler für Schüler entwickelt, um den Schulalltag zu vereinfachen.

### Entwicklungsgeschichte
- **130MB → 9MB**: Massive Größenreduzierung durch Asset-Optimierung
- Kontinuierliche Verbesserung der Benutzeroberfläche
- Implementierung von Offline-Funktionalität
- Einführung intelligenter PDF-Verarbeitung

## ⚖️ Lizenz & Nutzungsrechte

Dieses Projekt steht unter der **Creative Commons BY-NC-ND 4.0 Lizenz**.

**Das bedeutet**:
- ✅ **Nutzung** für private und bildende Zwecke erlaubt
- ❌ **Kommerzielle Nutzung** nicht gestattet
- ❌ **Veränderung und Weiterverbreitung** nicht erlaubt
- ❌ **Neuveröffentlichung** unter anderem Namen nicht gestattet

Nur der ursprüngliche Entwickler darf offizielle Versionen erstellen und veröffentlichen.

**Vollständige Lizenz**: [LICENSE](LICENSE)

---

**Entwickelt mit ❤️ von Luka Löhr für die Schulgemeinschaft des Lessing-Gymnasiums Karlsruhe**
