# 🔒 Datenschutz

## Datenschutz-Grundsätze

Die LGKA+ App wurde mit **"Privacy by Design"** entwickelt. Das bedeutet: Datenschutz ist von Anfang an mitgedacht, nicht nachträglich hinzugefügt.

### Wichtigste Punkte

- **Keine Datensammlung** von persönlichen Informationen
- **Keine Tracking-Technologien** oder Analytics
- **Keine Werbung** oder Werbe-IDs
- **Lokale Datenspeicherung** nur für App-Funktion
- **Verschlüsselte Verbindungen** zum Server

## Was die App speichert

### Lokal auf deinem Gerät

**PDF-Dateien:**
- Die heruntergeladenen Vertretungspläne
- Werden automatisch überschrieben bei neuen Versionen
- Werden bei App-Deinstallation vollständig gelöscht

**App-Einstellungen:**
- Deine gewählten Einstellungen (PDF-Viewer, Datumsanzeige)
- Anmeldestatus (dass du angemeldet bist, nicht die Zugangsdaten)
- Verwendung der App (nur für Review-Anfrage nach 20 Öffnungen)

### Was NICHT gespeichert wird

- **Keine Zugangsdaten** (werden nicht dauerhaft gespeichert)
- **Keine persönlichen Daten** (Name, Klasse, etc.)
- **Keine Nutzungsstatistiken** oder Analytics
- **Keine Geräteinformationen** außer für technischen Betrieb
- **Keine Standortdaten**

## Datenübertragung

### Verbindung zum Schulserver

**Was wird übertragen:**
- HTTP-Anfrage mit Zugangsdaten zur Authentifizierung
- Download der aktuellen PDF-Dateien

**Sicherheit:**
- **HTTPS-Verschlüsselung** für alle Verbindungen
- **Sichere Authentifizierung** gemäß Schulserver-Standards
- **Keine zusätzlichen Daten** über die PDF-Anfrage hinaus

### Keine Drittanbieter-Verbindungen

Die App kommuniziert **ausschließlich** mit:
- Dem Schulserver für PDF-Downloads
- Keinen Analytics-Diensten
- Keinen Werbenetzwerken
- Keinen Cloud-Diensten

## Berechtigungen

### Android-Berechtigungen

**Internet-Zugriff:**
- Erforderlich um Vertretungspläne herunterzuladen
- Nur zu Schulserver, keine anderen Verbindungen

**Speicher-Zugriff:**
- Für lokale Zwischenspeicherung der PDF-Dateien
- Nur temporärer Cache, keine dauerhaften Dateien

**Netzwerkstatus:**
- Um zu erkennen ob Internet verfügbar ist
- Für bessere Nutzerführung bei Verbindungsproblemen

### Was die App NICHT kann

- **Kein Zugriff** auf Kontakte, Kamera, Mikrofon
- **Kein Zugriff** auf andere Apps oder Dateien
- **Keine SMS** oder Anruf-Funktionen
- **Keine Standort-Verfolgung**

## DSGVO-Konformität

### Rechtsgrundlage

Die App verarbeitet **keine personenbezogenen Daten** im Sinne der DSGVO.

### Deine Rechte

Da keine personenbezogenen Daten verarbeitet werden, entstehen keine DSGVO-Betroffenenrechte. Du kannst aber jederzeit:

- Die App deinstallieren (entfernt alle lokalen Daten)
- Den Entwickler kontaktieren bei Fragen

### Datenschutz-Folgenabschätzung

**Risiko für Nutzer:** **Minimal**
- Keine Identifizierung möglich
- Keine Profile oder Tracking
- Lokale Datenspeicherung nur für App-Funktion

## Besondere Schutzmaßnahmen

### Code-Transparenz

- **Open Source**: Vollständiger Quellcode auf GitHub einsehbar
- **Community-Review**: Code kann von jedem geprüft werden
- **Keine versteckten Funktionen**: Alles dokumentiert und nachvollziehbar

### Technische Sicherheit

- **Code-Verschleierung** in Release-Versionen gegen Reverse Engineering
- **Sichere HTTP-Verbindungen** mit Certificate Pinning
- **Minimale Berechtigungen** nur für notwendige Funktionen

## Externe Dienste

### GitHub (nur für Downloads)

Wenn du die App von GitHub herunterlädst, gelten die [GitHub-Datenschutzbestimmungen](https://docs.github.com/de/site-policy/privacy-policies/github-privacy-statement).

**Die App selbst** kommuniziert **nicht** mit GitHub oder anderen externen Diensten.

## Kontakt zum Datenschutz

### Bei Fragen

Wenn du Fragen zum Datenschutz hast, wende dich an:

**E-Mail:** lgka.vertretungsplan@gmail.com

### Datenschutz-Verantwortlicher

**Luka Löhr** (Entwickler)  
Privates Schülerprojekt  
Kontakt über: lgka.vertretungsplan@gmail.com

**Hinweis:** Dies ist ein privates Projekt ohne kommerzielle Interessen. Der Entwickler ist bemüht, höchste Datenschutz-Standards einzuhalten.

## Änderungen

### Transparente Updates

Änderungen an der Datenschutz-Praxis werden:
- Im GitHub-Repository dokumentiert
- In neuen App-Versionen beschrieben
- Per E-Mail kommuniziert wenn erforderlich

### Letzte Aktualisierung

Diese Datenschutz-Information wurde zuletzt am **Januar 2025** aktualisiert.

---

**Bei Datenschutz-Fragen:** lgka.vertretungsplan@gmail.com