// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lgka_flutter/navigation/app_router.dart';
import 'package:lgka_flutter/providers/app_providers.dart';
import 'data/preferences_manager.dart';
import 'package:lgka_flutter/l10n/app_localizations.dart';
import 'utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Print welcome message
  AppLogger.welcome();
  
  // Enable edge-to-edge display - handled by native Android configuration now
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Initialize preferences manager
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
      overrides: [
        preferencesManagerProvider.overrideWith((ref) => preferencesManager),
      ],
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

  @override
  void initState() {
    super.initState();
    
    // Preload PDFs and weather data in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadData();
    });
  }

  Future<void> _preloadData() async {
    AppLogger.info('Starting background data preload');
    // Run all preloading operations in parallel for faster startup
    await Future.wait([
      _preloadPdfs(),
      _preloadWeatherData(),
      _preloadSchedules(),
    ]);
    AppLogger.success('Background preload complete');
  }

  Future<void> _preloadPdfs() async {
    try {
      AppLogger.init('Preloading PDF repository');
      final pdfRepo = ref.read(pdfRepositoryProvider);
      await pdfRepo.initialize();
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
        // Wrap the entire app with proper edge-to-edge inset handling
        return EdgeToEdgeWrapper(child: child ?? const SizedBox.shrink());
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
