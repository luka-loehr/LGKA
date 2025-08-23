// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'data/preferences_manager.dart';
import 'providers/app_providers.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable edge-to-edge display - handled by native Android configuration now
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Initialize preferences manager
  final preferencesManager = PreferencesManager();
  await preferencesManager.init();
  
  // Determine initial route
  String initialRoute;
  if (preferencesManager.isFirstLaunch) {
    initialRoute = AppRouter.welcome;
  } else if (preferencesManager.isAuthenticated) {
    initialRoute = AppRouter.home;
  } else {
    initialRoute = AppRouter.auth;
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
    // Run all preloading operations in parallel for faster startup
    await Future.wait([
      _preloadPdfs(),
      _preloadWeatherData(),
      _preloadSchedules(),
    ]);
  }

  Future<void> _preloadPdfs() async {
    try {
      final pdfRepo = ref.read(pdfRepositoryProvider);
      await pdfRepo.initialize();
    } catch (e) {
      debugPrint('Error preloading PDFs: $e');
    }
  }

  Future<void> _preloadWeatherData() async {
    try {
      final weatherDataNotifier = ref.read(weatherDataProvider.notifier);
      await weatherDataNotifier.preloadWeatherData();
    } catch (e) {
      debugPrint('Error preloading weather data: $e');
    }
  }

  Future<void> _preloadSchedules() async {
    try {
      final scheduleNotifier = ref.read(scheduleProvider.notifier);
      await scheduleNotifier.loadSchedules();
    } catch (e) {
      debugPrint('Error preloading schedules: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LGKA+ Vertretungsplan',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
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
