// Screenshot automation test.
//
// Run via Fastlane (see fastlane/Fastfile) or manually:
//
//   # Welcome screen
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshot_test.dart \
//     -d "iPhone 16 Pro Max" \
//     --dart-define=SCREENSHOT_MODE=welcome
//
//   # Home, Weather, News screens
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshot_test.dart \
//     -d "iPhone 16 Pro Max" \
//     --dart-define=SCREENSHOT_MODE=main
//
// Screenshots are saved to SCREENSHOT_OUTPUT_DIR (set by Fastlane) or
// build/screenshots/ by default.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lgka_flutter/main.dart' as app;

// Controlled via --dart-define=SCREENSHOT_MODE=welcome|main
const _mode = String.fromEnvironment('SCREENSHOT_MODE', defaultValue: 'main');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_mode == 'welcome') {
    _welcomeScreenshots(binding);
  } else {
    _mainScreenshots(binding);
  }
}

// ─── Welcome ─────────────────────────────────────────────────────────────────

void _welcomeScreenshots(IntegrationTestWidgetsFlutterBinding binding) {
  testWidgets('01_welcome', (tester) async {
    // Clear prefs so the app routes to the welcome screen on launch.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await _settle(tester);

    await binding.takeScreenshot('01_welcome');
  });
}

// ─── Home / Weather / News ───────────────────────────────────────────────────

void _mainScreenshots(IntegrationTestWidgetsFlutterBinding binding) {
  testWidgets('02_home_03_weather_04_news', (tester) async {
    // Seed prefs so the app boots straight to the home screen.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);
    await prefs.setBool('onboarding_completed', true);
    await prefs.setBool('is_authenticated', true);
    await prefs.setString('accent_color', 'blue');
    await prefs.setString('theme_mode', 'system');

    app.main();

    // Give the home screen and background data loads time to settle.
    await _settle(tester, seconds: 10);

    // ── 02 Home ──
    await binding.takeScreenshot('02_home');

    // ── 03 Weather screen ──
    // Tap the home screen's weather card to open the full weather screen,
    // then screenshot the weather screen once it has settled.
    await tester.tap(find.byKey(const Key('weather_card')));
    await _settle(tester, seconds: 5);
    await binding.takeScreenshot('03_weather');

    // Go back to home.
    await tester.pageBack();
    await _settle(tester);

    // ── 04 News screen ──
    // Tap the AppBar news icon to open the full news screen,
    // then screenshot the news screen once it has settled.
    await tester.tap(find.byIcon(Icons.newspaper_outlined));
    await _settle(tester, seconds: 5);
    await binding.takeScreenshot('04_news');
  });
}

// ─── Helper ──────────────────────────────────────────────────────────────────

/// pumpAndSettle with a generous timeout; on expiry just pumps once so we
/// still capture the current frame rather than throwing.
Future<void> _settle(WidgetTester tester, {int seconds = 5}) async {
  try {
    await tester.pumpAndSettle(timeout: Duration(seconds: seconds));
  } catch (_) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}
