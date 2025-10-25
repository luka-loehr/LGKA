// Copyright Luka Löhr 2025

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesManager extends ChangeNotifier {
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyAuthenticated = 'is_authenticated';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyDebugMode = 'is_debug_mode';
  static const String _keyShowNavigationDebug = 'show_navigation_debug';
  static const String _keyAccentColor = 'accent_color';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyKrankmeldungInfoShown = 'krankmeldung_info_shown';
  static const String _keyLastPdfSearch = 'last_pdf_search_query';
  static const String _keyLastPdfPage = 'last_pdf_search_page';
  // Per-schedule keys (exclude substitution plans)
  static const String _keyLastPage5to10 = 'last_schedule_5_10_page';
  static const String _keyLastPageJ11J12 = 'last_schedule_j11_12_page';
  static const String _keyLastQuery5to10 = 'last_schedule_5_10_query';
  static const String _keyLastQueryJ11J12 = 'last_schedule_j11_12_query';

  late final SharedPreferences _prefs;

  // Initialize the preferences manager
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Ensure defaults on first run
    if (!_prefs.containsKey(_keyAccentColor)) {
      await _prefs.setString(_keyAccentColor, 'blue');
    }
  }

  // First launch status
  bool get isFirstLaunch => _prefs.getBool(_keyFirstLaunch) ?? true;

  Future<void> setFirstLaunch(bool value) async {
    await _prefs.setBool(_keyFirstLaunch, value);
    notifyListeners();
  }

  // Authentication status
  bool get isAuthenticated => _prefs.getBool(_keyAuthenticated) ?? false;

  Future<void> setAuthenticated(bool value) async {
    await _prefs.setBool(_keyAuthenticated, value);
    notifyListeners();
  }

  // Onboarding completed (welcome + info)
  bool get onboardingCompleted => _prefs.getBool(_keyOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_keyOnboardingCompleted, value);
    notifyListeners();
  }

  // Debug mode status
  bool get isDebugMode => _prefs.getBool(_keyDebugMode) ?? false;

  Future<void> setDebugMode(bool value) async {
    await _prefs.setBool(_keyDebugMode, value);
    notifyListeners();
  }


  
  // Show navigation debug window (disabled by default)
  bool get showNavigationDebug => _prefs.getBool(_keyShowNavigationDebug) ?? false;

  Future<void> setShowNavigationDebug(bool value) async {
    await _prefs.setBool(_keyShowNavigationDebug, value);
    notifyListeners();
  }

  // Accent color preference
  String get accentColor => _prefs.getString(_keyAccentColor) ?? 'blue';

  Future<void> setAccentColor(String color) async {
    await _prefs.setString(_keyAccentColor, color);
    notifyListeners();
  }

  // Vibration preference
  bool get vibrationEnabled => _prefs.getBool(_keyVibrationEnabled) ?? true;

  Future<void> setVibrationEnabled(bool value) async {
    await _prefs.setBool(_keyVibrationEnabled, value);
    notifyListeners();
  }

  // Krankmeldung info shown preference
  bool get krankmeldungInfoShown => _prefs.getBool(_keyKrankmeldungInfoShown) ?? false;

  Future<void> setKrankmeldungInfoShown(bool value) async {
    await _prefs.setBool(_keyKrankmeldungInfoShown, value);
    notifyListeners();
  }

  // Last PDF search query (for schedule convenience)
  String? get lastPdfSearchQuery => _prefs.getString(_keyLastPdfSearch);

  Future<void> setLastPdfSearchQuery(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _prefs.remove(_keyLastPdfSearch);
    } else {
      await _prefs.setString(_keyLastPdfSearch, value);
    }
    notifyListeners();
  }

  // Last matched PDF page (1-based for readability)
  int? get lastPdfSearchPage {
    final page = _prefs.getInt(_keyLastPdfPage);
    if (page == null || page < 1) return null;
    return page;
  }

  Future<void> setLastPdfSearchPage(int? page) async {
    if (page == null || page < 1) {
      await _prefs.remove(_keyLastPdfPage);
    } else {
      await _prefs.setInt(_keyLastPdfPage, page);
    }
    notifyListeners();
  }

  // Per-schedule: last page (1-based)
  int? get lastSchedulePage5to10 {
    final page = _prefs.getInt(_keyLastPage5to10);
    if (page == null || page < 1) return null;
    return page;
  }

  Future<void> setLastSchedulePage5to10(int? page) async {
    if (page == null || page < 1) {
      await _prefs.remove(_keyLastPage5to10);
    } else {
      await _prefs.setInt(_keyLastPage5to10, page);
    }
    notifyListeners();
  }

  int? get lastSchedulePageJ11J12 {
    final page = _prefs.getInt(_keyLastPageJ11J12);
    if (page == null || page < 1) return null;
    return page;
  }

  Future<void> setLastSchedulePageJ11J12(int? page) async {
    if (page == null || page < 1) {
      await _prefs.remove(_keyLastPageJ11J12);
    } else {
      await _prefs.setInt(_keyLastPageJ11J12, page);
    }
    notifyListeners();
  }

  // Per-schedule: last query (optional convenience)
  String? get lastScheduleQuery5to10 => _prefs.getString(_keyLastQuery5to10);

  Future<void> setLastScheduleQuery5to10(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _prefs.remove(_keyLastQuery5to10);
    } else {
      await _prefs.setString(_keyLastQuery5to10, value);
    }
    notifyListeners();
  }

  String? get lastScheduleQueryJ11J12 => _prefs.getString(_keyLastQueryJ11J12);

  Future<void> setLastScheduleQueryJ11J12(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _prefs.remove(_keyLastQueryJ11J12);
    } else {
      await _prefs.setString(_keyLastQueryJ11J12, value);
    }
    notifyListeners();
  }

  // Clear all preferences
  Future<void> clearAllPreferences() async {
    await _prefs.clear();
    notifyListeners();
  }
} 