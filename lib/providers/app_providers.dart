// Copyright Luka Löhr 2026
//
// Re-export barrel — kept for backwards compatibility.
// New code should import preferences_provider.dart or theme_providers.dart
// directly, and service providers from their respective feature application/.

export 'preferences_provider.dart';
export 'theme_providers.dart';
export '../features/schedule/application/schedule_provider.dart'
    show scheduleServiceProvider;
export '../features/news/application/news_provider.dart'
    show newsServiceProvider;
export '../features/substitution/application/substitution_provider.dart'
    show substitutionServiceProvider;
