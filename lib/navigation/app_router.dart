// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/welcome_screen.dart';
import '../screens/info_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/schedule_page.dart';
import '../screens/legal_screen.dart';
import '../screens/webview_screen.dart';

class AppRouter {
  // Route names
  static const String welcome = '/welcome';
  static const String info = '/info';
  static const String auth = '/auth';
  static const String home = '/';
  static const String pdfViewer = '/pdf-viewer';
  static const String schedule = '/schedule';
  static const String legal = '/legal';
  static const String webview = '/webview';

  static GoRouter createRouter({required String initialLocation}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: welcome,
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: info,
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const InfoScreen(),
            transitionsBuilder: _infoTransition,
            transitionDuration: const Duration(milliseconds: 400),
          ),
        ),
        GoRoute(
          path: auth,
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const AuthScreen(),
            transitionsBuilder: _infoTransition,
            transitionDuration: const Duration(milliseconds: 400),
          ),
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
          path: legal,
          builder: (context, state) => const LegalScreen(),
        ),
        GoRoute(
          path: webview,
          pageBuilder: (context, state) {
            final data = state.extra as Map<String, dynamic>;
            return CustomTransitionPage(
              child: InAppWebViewScreen(
                url: data['url'] as String,
                title: data['title'] as String?,
                headers: data['headers'] as Map<String, String>?,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  )),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            );
          },
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

  // Info screen transitions (smooth slide in with fade, matching auth style)
  static Widget _infoTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Smooth slide in from right with sophisticated curve
    var slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    // Subtle scale animation for polish
    var scaleAnimation = Tween<double>(begin: 0.98, end: 1.0)
        .animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));

    // Smooth fade in
    var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
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