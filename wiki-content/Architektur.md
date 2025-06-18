# 🏛️ App-Architektur

## Überblick

Die LGKA+ App verwendet eine moderne, saubere Architektur basierend auf **Flutter** und bewährten Design-Patterns.

## Technologie-Stack

### Framework & Sprachen
- **Flutter 3.8.0+** – Cross-Platform UI Framework
- **Dart 3.8.1+** – Programmiersprache
- **Material Design 3** – Design-System mit Dark Theme

### Kern-Dependencies
- **Riverpod 2.6.1** – State Management
- **go_router 15.1.2** – Navigation & Routing
- **http 1.2.2** – Netzwerkkommunikation
- **syncfusion_flutter_pdf** – PDF-Metadaten-Extraktion
- **pdfx** – PDF-Anzeige

## App-Struktur

### Hauptkomponenten

```
lib/
├── main.dart                   # App-Einstiegspunkt
├── data/                       # Datenmanagement
├── providers/                  # State Management (Riverpod)
├── screens/                    # UI-Bildschirme
├── navigation/                 # Routing-Logik
├── services/                   # Externe Services
└── theme/                      # Design-System
```

### Data Layer

**PDF Repository** (`pdf_repository.dart`):
- PDF-Download mit HTTP Basic Auth
- Intelligentes Caching mit Wochentag-Namen
- Metadaten-Extraktion in Background-Isolates
- Automatische Retry-Mechanismen

**Preferences Manager** (`preferences_manager.dart`):
- App-Einstellungen über SharedPreferences
- Anmeldestatus-Verwaltung
- Erste-Nutzung-Erkennung

### Presentation Layer

**Screens** (6 Hauptbildschirme):
- `welcome_screen.dart` – Onboarding
- `auth_screen.dart` – Anmeldung mit adaptiver Keyboard-Animation
- `home_screen.dart` – Hauptbildschirm mit PDF-Buttons
- `pdf_viewer_screen.dart` – Integrierter PDF-Viewer
- `settings_screen.dart` – App-Konfiguration
- `legal_screen.dart` – Rechtliche Hinweise

### State Management

**Riverpod Provider** (`app_providers.dart`):
- `pdfRepositoryProvider` – PDF-Daten und Downloads
- `preferencesManagerProvider` – App-Einstellungen
- `isAuthenticatedProvider` – Anmeldestatus

## Design Patterns

### Repository Pattern
- Trennung von Datenlogik und UI
- Zentrale PDF-Verwaltung
- Testbare Abstraktion

### Provider Pattern
- Reaktive State-Updates
- Dependency Injection
- Immutable State

### Service Locator
- `HapticService` – Haptisches Feedback
- `ReviewService` – In-App-Review nach 20 Öffnungen
- `FileOpenerService` – Externe App-Integration

## Datenfluss

```
UI Screens ↔ Riverpod Providers ↔ Repositories ↔ Local Storage/Network
```

**Beispiel PDF-Download:**
1. UI ruft `pdfRepository.preloadPdfs()` auf
2. Repository prüft Netzwerkstatus
3. HTTP-Request an Schulserver
4. PDF-Metadaten in Background-Isolate extrahieren
5. Lokale Speicherung mit Wochentag-Namen
6. UI-Update über Riverpod

## Networking

### PDF-Download-System
- **Basic Auth** mit fest kodierten Credentials
- **HTTPS-Verschlüsselung** für alle Verbindungen
- **Exponentielles Backoff** bei Verbindungsproblemen
- **Slow-Connection-Detection** nach 3 Sekunden

### Intelligentes Caching
- **Wochentag-basierte Dateinamen** (`montag.pdf`, `dienstag.pdf`)
- **Automatische Überschreibung** bei neuen Versionen
- **Offline-First Architektur**

## Performance-Optimierungen

### Background Processing
- **PDF-Verarbeitung in Isolates** verhindert UI-Blocking
- **Lazy Loading** der UI-Komponenten
- **Connection Pooling** für HTTP-Requests

### Build-Optimierungen
- **R8 Code Shrinking** reduziert APK-Größe um 70%
- **Icon Tree-Shaking** reduziert Font-Größe um 99%+
- **Resource Shrinking** entfernt ungenutzte Assets

## Navigation

### Router-basierte Navigation
- **go_router** für deklarative Navigation
- **Typsichere Routes** mit `AppRouter`-Klasse
- **Bedingte Initial-Route** basierend auf App-Status

### Screen-Flow
```
Welcome → Auth → Home ⟷ PDF Viewer
              ↓
          Settings / Legal
```

## Konfiguration

### Zentrale App-Konfiguration
- **app_config.yaml** für plattformübergreifende Einstellungen
- **Automatische Synchronisation** zwischen Android und iOS
- **Dart-Script** für Konfiguration-Anwendung

### Platform-spezifische Anpassungen
- **Android**: Edge-to-Edge Display, Adaptive Icons
- **iOS**: App-Name über xcconfig, Bundle-ID Synchronisation

## Sicherheit

### Datenschutz by Design
- **Keine Analytics** oder Tracking
- **Lokale Datenspeicherung** nur für App-Funktion
- **Verschlüsselte Server-Kommunikation**

### Code-Schutz
- **ProGuard/R8-Optimierung** in Release-Builds
- **Open Source** für Transparenz
- **Minimale Berechtigungen**

---

**Architektur-Details:** lgka.vertretungsplan@gmail.com