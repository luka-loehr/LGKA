// Copyright Luka Löhr 2025

import 'package:shared_preferences/shared_preferences.dart';

class PreferencesManager {
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyAuthenticated = 'is_authenticated';
  static const String _keyDebugMode = 'is_debug_mode';
  static const String _keyShowDates = 'show_dates_with_weekdays';
  static const String _keyPlanOpenCount = 'plan_open_count';
  static const String _keyHasRequestedReview = 'has_requested_review';
  static const String _keyShowNavigationDebug = 'show_navigation_debug';
  static const String _keyUseBuiltInPdfViewer = 'use_built_in_pdf_viewer';

  late final SharedPreferences _prefs;

  // Initialize the preferences manager
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // First launch status
  bool get isFirstLaunch => _prefs.getBool(_keyFirstLaunch) ?? true;

  Future<void> setFirstLaunch(bool value) async {
    await _prefs.setBool(_keyFirstLaunch, value);
  }

  // Authentication status
  bool get isAuthenticated => _prefs.getBool(_keyAuthenticated) ?? false;

  Future<void> setAuthenticated(bool value) async {
    await _prefs.setBool(_keyAuthenticated, value);
  }

  // Debug mode status
  bool get isDebugMode => _prefs.getBool(_keyDebugMode) ?? false;

  Future<void> setDebugMode(bool value) async {
    await _prefs.setBool(_keyDebugMode, value);
  }

  // Show dates with weekdays (enabled by default)
  bool get showDatesWithWeekdays => _prefs.getBool(_keyShowDates) ?? true;

  Future<void> setShowDatesWithWeekdays(bool value) async {
    await _prefs.setBool(_keyShowDates, value);
  }
  
  // Show navigation debug window (enabled by default)
  bool get showNavigationDebug => _prefs.getBool(_keyShowNavigationDebug) ?? true;

  Future<void> setShowNavigationDebug(bool value) async {
    await _prefs.setBool(_keyShowNavigationDebug, value);
  }
  
  // Use built-in PDF viewer (enabled by default)
  bool get useBuiltInPdfViewer => _prefs.getBool(_keyUseBuiltInPdfViewer) ?? true;

  Future<void> setUseBuiltInPdfViewer(bool value) async {
    await _prefs.setBool(_keyUseBuiltInPdfViewer, value);
  }
  
  // Plan open count
  int get planOpenCount => _prefs.getInt(_keyPlanOpenCount) ?? 0;
  
  Future<void> incrementPlanOpenCount() async {
    final currentCount = planOpenCount;
    await _prefs.setInt(_keyPlanOpenCount, currentCount + 1);
  }
  
  // Review request status
  bool get hasRequestedReview => _prefs.getBool(_keyHasRequestedReview) ?? false;
  
  Future<void> setHasRequestedReview(bool value) async {
    await _prefs.setBool(_keyHasRequestedReview, value);
  }

  // Clear all preferences
  Future<void> clearAllPreferences() async {
    await _prefs.clear();
  }
} 