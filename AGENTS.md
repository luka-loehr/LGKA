# AGENTS.md — LGKA+ Flutter App

AI coding agent guide for the LGKA+ project. Read this before making changes.

---

## Project Overview

LGKA+ is a Flutter mobile app for Lessing-Gymnasium Karlsruhe. It shows substitution plans, timetables (PDF), a news feed, weather, and school events. Published on both the App Store and Google Play.

- **Package:** `com.lgka`
- **Version source of truth:** `pubspec.yaml` (`version: <name>+<build>`)
- **Platforms:** iOS 12.0+, Android SDK 21+
- **Languages:** German (`de`) and English (`en`)

---

## Repository Layout

```
agents/                    AI agent rules and release templates (see below)
android/                   Android platform code (Kotlin, Gradle KTS)
app_config/                Centralized cross-platform config (name, icon, package ID)
app_store_assets/          Store screenshots and banners
assets/                    App images and icons
docs/                      HTML pages deployed to GitHub Pages (privacy, imprint)
fastlane/                  Screenshot automation (see below)
integration_test/          Integration tests (screenshot automation)
ios/                       iOS Xcode project
lib/                       All Flutter/Dart source code
test_driver/               flutter drive entry point
.github/workflows/         CI/CD workflows (see below)
```

---

## lib/ Architecture

Clean Architecture with feature-based separation.

```
lib/
  main.dart                App entry point — initializes timezone, prefs, routing
  config/                  App credentials (hardcoded, used for onboarding auth)
  data/                    PreferencesManager (SharedPreferences wrapper)
  navigation/              GoRouter setup — all routes defined in AppRouter
  providers/               Root Riverpod providers (theme, accent color, prefs)
  services/                CacheService, HapticService
  theme/                   Material 3 themes (light/dark, accent color variants)
  utils/                   AppLogger, AppInfo, retry helpers
  widgets/                 Shared UI components
  l10n/                    .arb localization files + generated AppLocalizations
  features/
    events/                School calendar events
    home/                  Home screen dashboard
    news/                  News feed (scrapes school website)
    onboarding/            First-run flow (welcome → info → accent → appearance → auth)
    pdf_viewer/            PDF viewer for timetables
    schedule/              Timetable PDFs with class search
    settings/              App settings modal
    substitution/          Substitution plan (main feature)
    weather/               Open-Meteo weather (hardcoded to school GPS coordinates)
```

Each full-stack feature has `application/` (Riverpod providers), `data/` (service/repository), `domain/` (models), and `presentation/` (screens/widgets).

---

## Key Patterns

- **Navigation:** `go_router`. All route strings are constants on `AppRouter`. Use `context.push()` for stack pushes, `context.go()` for replacing.
- **State:** Riverpod (`flutter_riverpod`). Providers live in `application/` inside each feature.
- **Onboarding gate:** `main.dart` reads three SharedPreferences keys at startup to decide the initial route: `is_first_launch`, `onboarding_completed`, `is_authenticated`.
- **Localization:** `AppLocalizations.of(context)!` everywhere. Add new strings to both `.arb` files in `lib/l10n/`.
- **Theming:** Never hardcode colors. Use `context.appPrimaryText`, `context.appBgColor`, etc. from `theme/app_theme.dart`.

---

## Common Commands

```bash
flutter pub get            # Install dependencies
flutter run                # Run on connected device/simulator
flutter build apk          # Android release APK
flutter build appbundle    # Android App Bundle (Play Store)
flutter build ipa          # iOS archive (requires Xcode)
flutter gen-l10n           # Regenerate localization files after editing .arb files
```

---

## Screenshot Automation (Fastlane)

Screenshots are automated via `fastlane/` and `integration_test/`.

### What it captures

| # | Screen | Route |
|---|--------|-------|
| 01 | Welcome | `/welcome` |
| 02 | Home | `/` |
| 03 | Weather | `/weather` |
| 04 | News | `/news` |

For each: 2 locales (`de`, `en`) × 2 form factors (`phone`, `tablet`) = **8 output files**.

### Output location

```
app_store_assets/screenshots/<locale>/<platform>/<form_factor>/
  01_welcome.png
  02_home.png
  03_weather.png
  04_news.png
```

### How it works

1. `fastlane/Fastfile` clears the output folder, sets the simulator/emulator locale, then calls `flutter drive` twice per combo — once with `--dart-define=SCREENSHOT_MODE=welcome` and once with `SCREENSHOT_MODE=main`.
2. `integration_test/screenshot_test.dart` seeds SharedPreferences to control the initial route, launches the app, navigates to each screen, and calls `binding.takeScreenshot(name)`.
3. `test_driver/integration_test.dart` receives screenshot bytes from the device and writes them to `SCREENSHOT_OUTPUT_DIR` on the host.
4. After all shots are taken the lane auto-commits and pushes the new PNGs.

### Running

```bash
bundle exec fastlane screenshots_ios
```

### Prerequisites

- iOS: Install simulators in Xcode → Platforms: `iPhone 16 Pro Max`, `iPad Pro (12.9-inch) (6th generation)`

---

## Release Workflow (agents/)

The `agents/` folder contains rules and templates for the full release process.

```
agents/
  agent-rules/
    release.md             Step-by-step release workflow for agents
  templates/
    release_notes_template.md     GitHub release notes format
    appstore_release_template.md  App Store release notes (German, student-friendly)
```

Trigger the release workflow with: _"prepare release"_, _"release"_, or _"new release"_.

The workflow covers: version bump in `pubspec.yaml`, git tag, GitHub release creation, App Store release notes, and build/upload steps. Read `agents/agent-rules/release.md` in full before starting a release.

---

## GitHub Workflows (.github/workflows/)

| File | Trigger | Purpose |
|------|---------|---------|
| `deploy-ghpages.yml` | Push to `main` touching `docs/` or HTML files | Deploys `docs/` to GitHub Pages (privacy policy, imprint) |
| `dependabot.yml` | Daily 13:00 UTC | Opens PRs for outdated pub and GitHub Actions dependencies |

---

## App Configuration System (app_config/)

Single source of truth for cross-platform metadata (app name, package ID, icon). When changing the app name, icon, or bundle identifier, update `app_config/app_config.yaml` and run the apply script — do not edit Android/iOS config files directly. See `app_config/README.md` for full instructions.
