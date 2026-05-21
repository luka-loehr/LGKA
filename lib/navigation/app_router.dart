// Copyright Luka Löhr 2026

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/onboarding/presentation/what_you_can_do_screen.dart';
import '../features/onboarding/presentation/accent_color_screen.dart';
import '../features/onboarding/presentation/appearance_screen.dart';
import '../features/onboarding/presentation/auth_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/pdf_viewer/presentation/pdf_viewer/pdf_viewer.dart';
import '../features/schedule/presentation/schedule_page.dart';
import '../features/info/presentation/legal_screen.dart';
import '../features/pdf_viewer/presentation/webview_screen.dart';
import '../features/info/presentation/krankmeldung_info_screen.dart';
import '../features/settings/presentation/bug_report_screen.dart';
import '../features/news/presentation/news_screen.dart';
import '../features/news/presentation/news_detail_screen.dart';
import '../features/news/domain/news_models.dart';
import '../features/weather/presentation/weather_page.dart';

class AppRouter {
  static Page<dynamic> _buildAdaptivePage({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoPage<dynamic>(
        key: state.pageKey,
        child: child,
      );
    }
    
    return CustomTransitionPage<dynamic>(
      key: state.pageKey,
      child: child,
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
  }

  static Widget _buildPdfViewerRoute(BuildContext context, GoRouterState state) {
    final extra = state.extra;
    if (extra is! Map<String, dynamic>) {
      return _buildRouteErrorScreen(
        context,
        'Document could not be opened.',
      );
    }

    final file = extra['file'];
    final dayName = extra['dayName'];
    final targetPages = extra['targetPages'];

    if (file is! File) {
      return _buildRouteErrorScreen(
        context,
        'Document could not be opened.',
      );
    }

    final parsedTargetPages = switch (targetPages) {
      final List<int> pages => pages,
      final List<dynamic> pages when pages.every((page) => page is int) =>
        pages.cast<int>(),
      null => null,
      _ => null,
    };

    return PDFViewerScreen(
      pdfFile: file,
      dayName: dayName as String?,
      targetPages: parsedTargetPages,
    );
  }

  static Widget _buildRouteErrorScreen(BuildContext context, String message) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // Route names
  static const String welcome = '/welcome';
  static const String whatYouCanDo = '/what-you-can-do';
  static const String accentColor = '/accent-color';
  static const String appearance = '/appearance';
  static const String auth = '/auth';
  static const String home = '/';
  static const String pdfViewer = '/pdf-viewer';
  static const String schedule = '/schedule';
  static const String legal = '/legal';
  static const String webview = '/webview';
  static const String krankmeldungInfo = '/krankmeldung-info';
  static const String bugReport = '/bug-report';
  static const String news = '/news';
  static const String newsDetail = '/news-detail';
  static const String weather = '/weather';

  static GoRouter createRouter({required String initialLocation}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: welcome,
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: whatYouCanDo,
          builder: (context, state) => const WhatYouCanDoScreen(),
        ),
        GoRoute(
          path: accentColor,
          builder: (context, state) => const AccentColorScreen(),
        ),
        GoRoute(
          path: appearance,
          builder: (context, state) => const AppearanceScreen(),
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
          builder: _buildPdfViewerRoute,
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
          path: krankmeldungInfo,
          builder: (context, state) => const KrankmeldungInfoScreen(),
        ),
        GoRoute(
          path: webview,
          pageBuilder: (context, state) {
            final data = state.extra as Map<String, dynamic>;
            return _buildAdaptivePage(
              context: context,
              state: state,
              child: InAppWebViewScreen(
                url: data['url'] as String,
                title: data['title'] as String?,
                headers: data['headers'] as Map<String, String>?,
                fromKrankmeldungInfo: data['fromKrankmeldungInfo'] as bool? ?? false,
              ),
            );
          },
        ),
        GoRoute(
          path: bugReport,
          pageBuilder: (context, state) {
            return _buildAdaptivePage(
              context: context,
              state: state,
              child: const BugReportScreen(),
            );
          },
        ),
        GoRoute(
          path: news,
          pageBuilder: (context, state) {
            return _buildAdaptivePage(
              context: context,
              state: state,
              child: const NewsScreen(),
            );
          },
        ),
        GoRoute(
          path: weather,
          pageBuilder: (context, state) {
            return _buildAdaptivePage(
              context: context,
              state: state,
              child: const WeatherPage(),
            );
          },
        ),
        GoRoute(
          path: newsDetail,
          pageBuilder: (context, state) {
            final extra = state.extra;
            if (extra is! NewsEvent) {
              return _buildAdaptivePage(
                context: context,
                state: state,
                child: _buildRouteErrorScreen(
                  context,
                  'News article could not be loaded.',
                ),
              );
            }
            return _buildAdaptivePage(
              context: context,
              state: state,
              child: NewsDetailScreen(event: extra),
            );
          },
        ),
      ],
    );
  }

} 