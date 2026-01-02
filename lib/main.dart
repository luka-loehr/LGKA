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
import 'package:lgka_flutter/providers/substitution_provider.dart';
import 'package:lgka_flutter/services/cache_service.dart';
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

class _LGKAAppState extends ConsumerState<LGKAApp> with WidgetsBindingObserver {
  late final _router = AppRouter.createRouter(initialLocation: widget.initialRoute);
  final _cacheService = CacheService();
  // Refresh timer runs every minute to proactively refresh expired caches
  static const Duration _cacheRefreshInterval = Duration(minutes: 1);
  Timer? _cacheRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Preload PDFs and weather data in background
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _preloadData();
      _startCacheRefreshTimer();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cacheRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // When app goes to background (paused or inactive), mark cache as invalid
    // This ensures cache will be invalid when user returns to the app
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      AppLogger.info('App backgrounded - marking cache as invalid');
      _cacheService.onAppBackgrounded();
    }
    // When app resumes, immediately refresh critical data (substitutions, weather)
    // so fresh data is ready when user accesses it
    else if (state == AppLifecycleState.resumed) {
      AppLogger.info('App resumed - cache invalidated, refreshing critical data');
      _refreshCriticalDataOnResume();
    }
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
      AppLogger.init('Preloading substitution plans');
      await ref.read(substitutionProvider.notifier).initialize();
      AppLogger.success('Substitution plans preloaded');
    } catch (e) {
      AppLogger.error('Failed to preload substitution plans', error: e);
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
      
      // Build class index for 5-10 schedule (runs after schedules are loaded)
      await scheduleNotifier.preloadClassIndex();
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
    _cacheRefreshTimer = Timer.periodic(_cacheRefreshInterval, (_) {
      unawaited(_refreshExpiredCaches());
    });
  }

  /// Refresh critical data immediately when app resumes (substitutions, weather)
  /// This ensures fresh data is ready when user accesses it
  Future<void> _refreshCriticalDataOnResume() async {
    // Immediately refresh substitutions and weather (most frequently accessed)
    final substitutionState = ref.read(substitutionProvider);
    if (!substitutionState.isCacheValid && substitutionState.hasAnyData) {
      AppLogger.info('App resumed: Immediately refreshing substitutions', module: 'Main');
      unawaited(ref.read(substitutionProvider.notifier).refreshInBackground());
    }

    final weatherState = ref.read(weatherDataProvider);
    final weatherLastUpdate = weatherState.lastUpdateTime;
    if (weatherLastUpdate == null ||
        _cacheService.isCacheExpired(CacheKey.weather, lastFetchTime: weatherLastUpdate)) {
      AppLogger.info('App resumed: Immediately refreshing weather', module: 'Main');
      unawaited(ref.read(weatherDataProvider.notifier).updateDataInBackground());
    }

    // Refresh schedules and news in background (less critical)
    final scheduleService = ref.read(scheduleServiceProvider);
    if (!scheduleService.hasValidCache && scheduleService.cachedSchedules != null) {
      AppLogger.debug('App resumed: Refreshing schedules in background', module: 'Main');
      unawaited(ref.read(scheduleProvider.notifier).refreshInBackground());
    }

    final newsService = ref.read(newsServiceProvider);
    if (!newsService.hasValidCache && newsService.cachedEvents != null) {
      AppLogger.debug('App resumed: Refreshing news in background', module: 'Main');
      unawaited(ref.read(newsProvider.notifier).refreshInBackground());
    }
    
    // Rebuild class index in background (schedule PDF may have changed)
    final scheduleNotifier = ref.read(scheduleProvider.notifier);
    scheduleNotifier.invalidateClassIndex();
    unawaited(scheduleNotifier.preloadClassIndex());
  }

  Future<void> _refreshExpiredCaches() async {
    AppLogger.debug('Cache refresh timer: Checking expired caches', module: 'Main');
    
    final substitutionState = ref.read(substitutionProvider);
    if (!substitutionState.isCacheValid && substitutionState.hasAnyData) {
      AppLogger.debug('Cache refresh timer: Triggering background refresh for substitutions', module: 'Main');
      unawaited(ref.read(substitutionProvider.notifier).refreshInBackground());
    }

    final scheduleService = ref.read(scheduleServiceProvider);
    if (!scheduleService.hasValidCache && scheduleService.cachedSchedules != null) {
      AppLogger.debug('Cache refresh timer: Triggering background refresh for schedules', module: 'Main');
      unawaited(ref.read(scheduleProvider.notifier).refreshInBackground());
    }

    final weatherState = ref.read(weatherDataProvider);
    final weatherLastUpdate = weatherState.lastUpdateTime;
    if (weatherLastUpdate == null ||
        _cacheService.isCacheExpired(CacheKey.weather, lastFetchTime: weatherLastUpdate)) {
      AppLogger.debug('Cache refresh timer: Triggering background refresh for weather', module: 'Main');
      unawaited(ref.read(weatherDataProvider.notifier).updateDataInBackground());
    }

    final newsService = ref.read(newsServiceProvider);
    if (!newsService.hasValidCache && newsService.cachedEvents != null) {
      AppLogger.debug('Cache refresh timer: Triggering background refresh for news', module: 'Main');
      unawaited(ref.read(newsProvider.notifier).refreshInBackground());
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
