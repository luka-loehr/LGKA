// Copyright Luka Löhr 2025

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:lgka_flutter/navigation/app_router.dart';
import 'package:lgka_flutter/providers/app_providers.dart';
import 'package:lgka_flutter/providers/schedule_provider.dart';
import 'package:lgka_flutter/providers/news_provider.dart';
import 'package:lgka_flutter/providers/fireworks_provider.dart';
import 'package:lgka_flutter/widgets/fireworks_overlay.dart';
import 'data/preferences_manager.dart';
import 'package:lgka_flutter/l10n/app_localizations.dart';
import 'utils/app_logger.dart';
import 'utils/app_info.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data
  tz.initializeTimeZones();
  
  // Print welcome message
  AppLogger.welcome();
  
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error('Flutter Error', error: details.exception, stackTrace: details.stack);
    // In debug mode, print to console as well
    if (!const bool.fromEnvironment('dart.vm.product')) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Platform Error', error: error, stackTrace: stack);
    return true;
  };

  // Custom Error Widget for Release Mode
  if (const bool.fromEnvironment('dart.vm.product')) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return const Material(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Ein unerwarteter Fehler ist aufgetreten.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Bitte starte die App neu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    };
  }
  
  // Enable edge-to-edge display - handled by native Android configuration now
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Restrict orientation to portrait only for phones (tablets can rotate)
  // This matches iOS behavior where iPhone is portrait-only but iPad supports all orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize app info
  await AppInfo.initialize();
  AppLogger.init('App version: ${AppInfo.fullVersion}');
  
  // Initialize preferences manager for initial route determination
  AppLogger.init('Initializing preferences manager');
  final preferencesManager = PreferencesManager();
  await preferencesManager.init();
  AppLogger.success('Preferences manager initialized');
  
  // Determine initial route with onboarding + auth gating
  String initialRoute;
  if (preferencesManager.isFirstLaunch || !preferencesManager.onboardingCompleted) {
    // Force Welcome → Info flow on fresh install or if onboarding not completed
    initialRoute = AppRouter.welcome;
    AppLogger.navigation('Routing to welcome screen (first launch: ${preferencesManager.isFirstLaunch}, onboarding: ${preferencesManager.onboardingCompleted})');
  } else if (preferencesManager.isAuthenticated) {
    initialRoute = AppRouter.home;
    AppLogger.navigation('Routing to home screen');
  } else {
    initialRoute = AppRouter.auth;
    AppLogger.navigation('Routing to auth screen');
  }
  
  runApp(
    ProviderScope(
      child: LGKAApp(initialRoute: initialRoute),
    ),
  );
}

class LGKAApp extends ConsumerStatefulWidget {
  final String initialRoute;
  
  const LGKAApp({super.key, required this.initialRoute});

  @override
  ConsumerState<LGKAApp> createState() => _LGKAAppState();
}

class _LGKAAppState extends ConsumerState<LGKAApp> {
  late final _router = AppRouter.createRouter(initialLocation: widget.initialRoute);
  static const Duration _cacheValidity = Duration(minutes: 5);
  Timer? _cacheRefreshTimer;

  @override
  void initState() {
    super.initState();

    // Preload PDFs and weather data in background
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _preloadData();
      _startCacheRefreshTimer();
    });
  }

  @override
  void dispose() {
    _cacheRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _preloadData() async {
    AppLogger.info('Starting background data preload');
    // Run all preloading operations in parallel for faster startup
    await Future.wait([
      _preloadPdfs(),
      _preloadWeatherData(),
      _preloadSchedules(),
      _preloadNews(),
    ]);
    AppLogger.success('Background preload complete');
    await _refreshExpiredCaches();
  }

  Future<void> _preloadPdfs() async {
    try {
      AppLogger.init('Preloading PDF repository');
      await ref.read(pdfRepositoryProvider.notifier).initialize();
      AppLogger.success('PDF repository preloaded');
    } catch (e) {
      AppLogger.error('Failed to preload PDFs', error: e);
    }
  }

  Future<void> _preloadWeatherData() async {
    try {
      AppLogger.init('Starting weather preload', module: 'Main');
      final weatherDataNotifier = ref.read(weatherDataProvider.notifier);
      await weatherDataNotifier.preloadWeatherData();
      AppLogger.success('Weather preload complete', module: 'Main');
    } catch (e) {
      AppLogger.error('Weather preload failed', module: 'Main', error: e);
    }
  }

  Future<void> _preloadSchedules() async {
    try {
      AppLogger.init('Preloading schedules');
      final scheduleNotifier = ref.read(scheduleProvider.notifier);
      await scheduleNotifier.loadSchedules();
      AppLogger.success('Schedules preloaded');
    } catch (e) {
      AppLogger.error('Failed to preload schedules', error: e);
    }
  }

  Future<void> _preloadNews() async {
    try {
      AppLogger.init('Preloading news');
      final newsNotifier = ref.read(newsProvider.notifier);
      await newsNotifier.loadNews();
      AppLogger.success('News preloaded');
    } catch (e) {
      AppLogger.error('Failed to preload news', error: e);
    }
  }

  void _startCacheRefreshTimer() {
    _cacheRefreshTimer?.cancel();
    _cacheRefreshTimer = Timer.periodic(_cacheValidity, (_) {
      unawaited(_refreshExpiredCaches());
    });
  }

  Future<void> _refreshExpiredCaches() async {
    final pdfRepository = ref.read(pdfRepositoryProvider);
    if (!pdfRepository.isCacheValid && pdfRepository.hasAnyData) {
      unawaited(ref.read(pdfRepositoryProvider.notifier).refreshInBackground());
    }

    final scheduleService = ref.read(scheduleServiceProvider);
    if (!scheduleService.hasValidCache && scheduleService.cachedSchedules != null) {
      unawaited(ref.read(scheduleProvider.notifier).refreshInBackground());
    }

    final weatherState = ref.read(weatherDataProvider);
    final weatherLastUpdate = weatherState.lastUpdateTime;
    if (weatherLastUpdate == null ||
        DateTime.now().difference(weatherLastUpdate) >= _cacheValidity) {
      unawaited(ref.read(weatherDataProvider.notifier).updateDataInBackground());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'LGKA+ Vertretungsplan',
      theme: theme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Wrap the entire app with proper edge-to-edge inset handling and fireworks overlay
        return FireworksOverlay(
          child: EdgeToEdgeWrapper(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

/// Wrapper widget that properly handles edge-to-edge display insets
/// for Android 15+ compatibility
class EdgeToEdgeWrapper extends StatelessWidget {
  final Widget child;
  
  const EdgeToEdgeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery for proper inset handling instead of deprecated SystemUiOverlayStyle
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        // Ensure proper padding is applied for system UI
        padding: MediaQuery.of(context).viewPadding,
      ),
      child: child,
    );
  }
}
