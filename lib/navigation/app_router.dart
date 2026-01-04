// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/what_you_can_do_screen.dart';
import '../screens/onboarding/accent_color_screen.dart';
import '../screens/onboarding/auth_screen.dart';
import '../screens/content/home_screen.dart';
import '../screens/viewers/pdf_viewer/pdf_viewer.dart';
import '../screens/content/schedule_page.dart';
import '../screens/info/legal_screen.dart';
import '../screens/viewers/webview_screen.dart';
import '../screens/info/krankmeldung_info_screen.dart';
import '../screens/settings/bug_report_screen.dart';
import '../screens/content/news_screen.dart';
import '../screens/content/news_detail_screen.dart';
import '../models/news_models.dart';

class AppRouter {
  // Route names
  static const String welcome = '/welcome';
  static const String whatYouCanDo = '/what-you-can-do';
  static const String accentColor = '/accent-color';
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
            return CustomTransitionPage(
              child: InAppWebViewScreen(
                url: data['url'] as String,
                title: data['title'] as String?,
                headers: data['headers'] as Map<String, String>?,
                fromKrankmeldungInfo: data['fromKrankmeldungInfo'] as bool? ?? false,
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
        GoRoute(
          path: bugReport,
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              child: const BugReportScreen(),
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
        GoRoute(
          path: news,
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              child: const NewsScreen(),
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
        GoRoute(
          path: newsDetail,
          pageBuilder: (context, state) {
            final event = state.extra as NewsEvent;
            return CustomTransitionPage(
              child: NewsDetailScreen(event: event),
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

} 