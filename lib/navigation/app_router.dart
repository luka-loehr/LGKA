import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/welcome_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';

class AppRouter {
  static const String welcome = '/welcome';
  static const String auth = '/auth';
  static const String home = '/home';

  static GoRouter createRouter({required String initialLocation}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: welcome,
          name: 'welcome',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const WelcomeScreen(),
            transitionsBuilder: _fadeTransition,
          ),
        ),
        GoRoute(
          path: auth,
          name: 'auth',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AuthScreen(),
            transitionsBuilder: _fadeTransition,
          ),
        ),
        GoRoute(
          path: home,
          name: 'home',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
            transitionsBuilder: _fadeTransition,
          ),
        ),
      ],
    );
  }

  static Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurveTween(curve: Curves.fastOutSlowIn).animate(animation),
      child: child,
    );
  }
} 