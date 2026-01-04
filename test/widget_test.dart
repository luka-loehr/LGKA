import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lgka_flutter/main.dart';
import 'package:lgka_flutter/data/preferences_manager.dart';
import 'package:lgka_flutter/providers/app_providers.dart';
import 'package:lgka_flutter/navigation/app_router.dart';
import 'package:lgka_flutter/features/weather/data/weather_service.dart';
import 'package:lgka_flutter/features/weather/application/weather_provider.dart';
import 'package:lgka_flutter/features/schedule/data/schedule_service.dart';
import 'package:lgka_flutter/features/substitution/data/substitution_service.dart';
import 'package:lgka_flutter/features/onboarding/presentation/welcome_screen.dart';
import 'package:lgka_flutter/features/weather/domain/weather_models.dart';
import 'package:lgka_flutter/features/schedule/domain/schedule_models.dart';

// Mocks
class MockSubstitutionService extends SubstitutionService {
  @override
  Future<void> initialize() async {
    // Do nothing
  }
  
  @override
  Future<void> refreshInBackground() async {
    // Do nothing
  }

  @override
  bool get isInitialized => true;
}

class MockWeatherService extends WeatherService {
  @override
  Future<List<WeatherData>> fetchWeatherData() async {
    return [];
  }
  
  @override
  Future<WeatherData?> getLatestWeatherData() async {
    return null;
  }
}

class MockScheduleService extends ScheduleService {
  @override
  Future<List<ScheduleItem>> getSchedules({bool forceRefresh = false}) async {
    return [];
  }
}

void main() {
  testWidgets('Smoke test - App starts up', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Create a mock preferences manager
    final preferencesManager = PreferencesManager();
    await preferencesManager.init();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesManagerProvider.overrideWith(() => PreferencesManagerNotifier()),
          // Override services to prevent network calls
          substitutionServiceProvider.overrideWith((ref) => MockSubstitutionService()),
          weatherServiceProvider.overrideWith((ref) => MockWeatherService()),
          scheduleServiceProvider.overrideWith((ref) => MockScheduleService()),
        ],
        child: const LGKAApp(initialRoute: AppRouter.welcome),
      ),
    );
    
    // Wait for animations and localizations to settle
    await tester.pumpAndSettle();

    // Verify that our initial screen is loaded
    expect(find.byType(WelcomeScreen), findsOneWidget); 
  });
}
