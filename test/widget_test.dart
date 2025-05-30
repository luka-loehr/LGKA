// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lgka_flutter/main.dart';
import 'package:lgka_flutter/data/preferences_manager.dart';
import 'package:lgka_flutter/providers/app_providers.dart';
import 'package:lgka_flutter/navigation/app_router.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Create a mock preferences manager for testing
    final preferencesManager = PreferencesManager();
    await preferencesManager.init();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesManagerProvider.overrideWithValue(preferencesManager),
        ],
        child: const LGKAApp(initialRoute: AppRouter.welcome),
      ),
    );

    // Verify that our initial screen is loaded
    expect(find.text('Willkommen!'), findsOneWidget);
  });
}
