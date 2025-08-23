// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/welcome_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/legal_screen.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/schedule_page.dart';

class AppRouter {
  static const String welcome = '/welcome';
  static const String auth = '/auth';
  static const String home = '/';
  static const String pdfViewer = '/pdf-viewer';
  static const String schedule = '/schedule';
  static const String settings = '/settings';
  static const String legal = '/legal';

  static GoRouter createRouter({required String initialLocation}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: welcome,
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: auth,
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: pdfViewer,
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>;
            return PDFViewerScreen(
              pdfFile: data['file'],
              dayName: data['dayName'],
            );
          },
        ),
        GoRoute(
          path: schedule,
          builder: (context, state) => const SchedulePage(),
        ),
        GoRoute(
          path: settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: legal,
          builder: (context, state) => const LegalScreen(),
        ),
      ],
    );
  }

  // Welcome screen transitions (smooth fade in)
  static Widget _welcomeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Smooth fade in with subtle scale for welcome screen
    var fadeAnimation = CurveTween(curve: Curves.easeOut).animate(animation);
    var scaleAnimation = Tween<double>(begin: 0.98, end: 1.0)
        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: child,
      ),
    );
  }

  // Auth screen transitions (same sophisticated style as home screen)
  static Widget _authTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Same sophisticated animation as home screen entry
    var slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    // Simple scale animation with slight bounce
    var scaleAnimation = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ));

    var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ));

    return SlideTransition(
      position: slideAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      ),
    );
  }

  // Home screen transitions (celebratory slide in with sophisticated effects)
  static Widget _homeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Simplified but elegant animation for home screen entry
    var slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    // Simple scale animation with slight bounce
    var scaleAnimation = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ));

    var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ));

    return SlideTransition(
      position: slideAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      ),
    );
  }
} 