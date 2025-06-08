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
  
  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
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
        preferencesManagerProvider.overrideWithValue(preferencesManager),
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
    
    // Preload PDFs in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadPdfs();
    });
  }

  Future<void> _preloadPdfs() async {
    try {
      final pdfRepo = ref.read(pdfRepositoryProvider);
      await pdfRepo.preloadPdfs();
      await pdfRepo.loadWeekdaysFromCachedPdfs();
    } catch (e) {
      debugPrint('Error preloading PDFs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LGKA+ Vertretungsplan',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
