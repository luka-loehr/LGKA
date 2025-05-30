# LGKA - Digitaler Vertretungsplan Lessing-Gymnasium Karlsruhe

Eine Flutter Mobile-Anwendung für den Zugriff auf digitale Vertretungspläne des Lessing-Gymnasiums Karlsruhe. Diese App bietet Schülern und Lehrern eine einfache Möglichkeit, Stundenplanänderungen und Ankündigungen einzusehen.

## Features

- Benutzerauthentifizierung (mit festen Zugangsdaten)
- Ansicht des digitalen Vertretungsplans für heute und morgen
- PDF-Download von der offiziellen Schulwebsite
- Extraktion von Metadaten aus PDFs (Wochentag, Aktualisierungsdatum)
- Caching von heruntergeladenen Plänen für Offline-Zugriff
- Dunkles Design
- Haptisches Feedback für Interaktionen
- Willkommensbildschirm für Erstnutzer

## Technische Details

- Entwickelt mit Flutter
- Uses Riverpod for state management
- Go Router for navigation
- PDF-Verarbeitung mit `syncfusion_flutter_pdf`
- HTTP-Anfragen mit `http`
- Öffnen von Dateien mit `open_filex`
- Abrufen von Paketinformationen mit `package_info_plus`
- Pfadverwaltung mit `path_provider`

## Getting Started

### Prerequisites

- Flutter SDK (version ^3.8.0)
- Dart SDK (latest stable)
- Android Studio or VS Code with Flutter extensions

### Installation

1.  Repository klonen:
    ```
    git clone https://github.com/YourUsername/LGKA.git
    ```
    *Hinweis: Ersetze YourUsername durch deinen GitHub-Benutzernamen.*

2.  Abhängigkeiten installieren:
   ```
   flutter pub get
   ```

3.  App starten:
    ```
    flutter run
    ```

## Datenschutz

Der Schutz deiner Daten ist uns wichtig. Die App erhebt, speichert oder verarbeitet keine personenbezogenen Daten. Weitere Informationen findest du in unserer Datenschutzerklärung:

[Datenschutzerklärung](https://luka-loehr.github.io/lgka-privacy/)

## Lizenz

This project is licensed under the MIT License - see the LICENSE file for details.
