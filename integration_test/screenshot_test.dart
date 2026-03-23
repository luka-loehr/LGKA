// Screenshot automation test.
//
// Each mode takes exactly ONE screenshot so the native xcrun capture in the
// driver fires while the simulator is still on the correct screen.
//
// Run via Fastlane (see fastlane/Fastfile) or manually:
//
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshot_test.dart \
//     -d "iPhone 17 Pro Max" \
//     --dart-define=SCREENSHOT_MODE=welcome|home|weather|news

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lgka_flutter/main.dart' as app;

const _mode = String.fromEnvironment('SCREENSHOT_MODE', defaultValue: 'home');
const _themeMode = String.fromEnvironment('THEME_MODE', defaultValue: 'light');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  switch (_mode) {
    case 'welcome':
      _screenshotWelcome(binding);
    case 'home':
      _screenshotHome(binding);
    case 'weather':
      _screenshotWeather(binding);
    case 'news':
      _screenshotNews(binding);
  }
}

// ─── Shared setup ─────────────────────────────────────────────────────────────

Future<void> _launchHome(WidgetTester tester) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_first_launch', false);
  await prefs.setBool('onboarding_completed', true);
  await prefs.setBool('is_authenticated', true);
  await prefs.setString('accent_color', 'blue');
  await prefs.setString('theme_mode', _themeMode);
  final originalOnError = FlutterError.onError;
  app.main();
  FlutterError.onError = originalOnError;
  await _settle(tester, seconds: 10);
}

// ─── Screens ──────────────────────────────────────────────────────────────────

void _screenshotWelcome(IntegrationTestWidgetsFlutterBinding binding) {
  testWidgets('01_welcome', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('theme_mode', _themeMode);
    final originalOnError = FlutterError.onError;
    app.main();
    FlutterError.onError = originalOnError;
    await _settle(tester);
    await binding.takeScreenshot('01_welcome');
  });
}

void _screenshotHome(IntegrationTestWidgetsFlutterBinding binding) {
  testWidgets('02_home', (tester) async {
    await _launchHome(tester);
    await binding.takeScreenshot('02_home');
  });
}

void _screenshotWeather(IntegrationTestWidgetsFlutterBinding binding) {
  testWidgets('03_weather', (tester) async {
    await _launchHome(tester);
    await tester.tap(find.byKey(const Key('weather_card')));
    await _settle(tester, seconds: 5);
    await binding.takeScreenshot('03_weather');
  });
}

void _screenshotNews(IntegrationTestWidgetsFlutterBinding binding) {
  testWidgets('04_news', (tester) async {
    await _launchHome(tester);
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
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      Duration(seconds: seconds),
    );
  } catch (_) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}
