// Copyright Luka Löhr 2026

import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class PreferencesManager {
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyAuthenticated = 'is_authenticated';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyDebugMode = 'is_debug_mode';
  static const String _keyShowNavigationDebug = 'show_navigation_debug';
  static const String _keyAccentColor = 'accent_color';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyKrankmeldungInfoShown = 'krankmeldung_info_shown';
  static const String _keyLastPdfSearch = 'last_pdf_search_query';
  static const String _keyLastPdfPage = 'last_pdf_search_page';
  // Selected class for schedule (e.g. "10b", "j11", "j12")
  static const String _keySelectedScheduleClass = 'selected_schedule_class';

  // Per-schedule keys (exclude substitution plans)
  static const String _keyLastPage5to10 = 'last_schedule_5_10_page';
  static const String _keyLastQuery5to10 = 'last_schedule_5_10_query';

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Initialize the preferences manager
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;

    // Ensure defaults on first run
    if (!_prefs!.containsKey(_keyAccentColor)) {
      await _prefs!.setString(_keyAccentColor, 'blue');
    }
    if (!_prefs!.containsKey(_keyThemeMode)) {
      await _prefs!.setString(_keyThemeMode, 'system');
    }

    // Migration from v2.4.x: selected_schedule_class is new in v2.5.0.
    // Old versions stored the class only in last_schedule_5_10_query — copy it over once.
    if (!_prefs!.containsKey(_keySelectedScheduleClass)) {
      final legacy = _prefs!.getString(_keyLastQuery5to10);
      if (legacy != null && legacy.trim().isNotEmpty) {
        await _prefs!.setString(_keySelectedScheduleClass, legacy.trim());
      }
    }
  }

  /// Check if preferences manager is initialized
  bool get isInitialized => _isInitialized;

  /// Get SharedPreferences instance, throwing if not initialized
  SharedPreferences get _safePrefs {
    if (!_isInitialized || _prefs == null) {
      throw StateError('PreferencesManager not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // First launch status
  bool get isFirstLaunch => _safePrefs.getBool(_keyFirstLaunch) ?? true;

  Future<void> setFirstLaunch(bool value) async {
    await _safePrefs.setBool(_keyFirstLaunch, value);
  }

  // Authentication status
  bool get isAuthenticated => _safePrefs.getBool(_keyAuthenticated) ?? false;

  Future<void> setAuthenticated(bool value) async {
    await _safePrefs.setBool(_keyAuthenticated, value);
  }

  // Onboarding completed (welcome + info)
  bool get onboardingCompleted => _safePrefs.getBool(_keyOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    await _safePrefs.setBool(_keyOnboardingCompleted, value);
  }

  // Debug mode status
  bool get isDebugMode => _safePrefs.getBool(_keyDebugMode) ?? false;

  Future<void> setDebugMode(bool value) async {
    await _safePrefs.setBool(_keyDebugMode, value);
    AppLogger.info('Debug mode ${value ? 'enabled' : 'disabled'}', module: 'Preferences');
  }


  
  // Show navigation debug window (disabled by default)
  bool get showNavigationDebug => _safePrefs.getBool(_keyShowNavigationDebug) ?? false;

  Future<void> setShowNavigationDebug(bool value) async {
    await _safePrefs.setBool(_keyShowNavigationDebug, value);
  }

  // Theme mode preference ('dark', 'light', 'system')
  String get themeMode => _safePrefs.getString(_keyThemeMode) ?? 'system';

  Future<void> setThemeMode(String mode) async {
    await _safePrefs.setString(_keyThemeMode, mode);
    AppLogger.info('Theme mode changed to $mode', module: 'Preferences');
  }

  // Accent color preference
  String get accentColor => _safePrefs.getString(_keyAccentColor) ?? 'blue';

  Future<void> setAccentColor(String color) async {
    final previousColor = accentColor;
    await _safePrefs.setString(_keyAccentColor, color);
    AppLogger.info('Accent color changed: $previousColor → $color', module: 'Preferences');
  }

  // Vibration preference
  bool get vibrationEnabled => _safePrefs.getBool(_keyVibrationEnabled) ?? true;

  Future<void> setVibrationEnabled(bool value) async {
    await _safePrefs.setBool(_keyVibrationEnabled, value);
    AppLogger.info('Vibration ${value ? 'enabled' : 'disabled'}', module: 'Preferences');
  }

  // Krankmeldung info shown preference
  bool get krankmeldungInfoShown => _safePrefs.getBool(_keyKrankmeldungInfoShown) ?? false;

  Future<void> setKrankmeldungInfoShown(bool value) async {
    await _safePrefs.setBool(_keyKrankmeldungInfoShown, value);
  }

  // Selected class for schedule (e.g. "10b", "j11", "j12")
  String? get selectedScheduleClass => _safePrefs.getString(_keySelectedScheduleClass);

  Future<void> setSelectedScheduleClass(String? className) async {
    if (className == null) {
      await _safePrefs.remove(_keySelectedScheduleClass);
    } else {
      await _safePrefs.setString(_keySelectedScheduleClass, className);
    }
  }

  // Last PDF search query (for schedule convenience)
  String? get lastPdfSearchQuery => _safePrefs.getString(_keyLastPdfSearch);

  Future<void> setLastPdfSearchQuery(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _safePrefs.remove(_keyLastPdfSearch);
    } else {
      await _safePrefs.setString(_keyLastPdfSearch, value);
    }
  }

  // Last matched PDF page (1-based for readability)
  int? get lastPdfSearchPage {
    final page = _safePrefs.getInt(_keyLastPdfPage);
    if (page == null || page < 1) return null;
    return page;
  }

  Future<void> setLastPdfSearchPage(int? page) async {
    if (page == null || page < 1) {
      await _safePrefs.remove(_keyLastPdfPage);
    } else {
      await _safePrefs.setInt(_keyLastPdfPage, page);
    }
  }

  // Per-schedule: last page (1-based)
  int? get lastSchedulePage5to10 {
    final page = _safePrefs.getInt(_keyLastPage5to10);
    if (page == null || page < 1) return null;
    return page;
  }

  Future<void> setLastSchedulePage5to10(int? page) async {
    if (page == null || page < 1) {
      await _safePrefs.remove(_keyLastPage5to10);
    } else {
      await _safePrefs.setInt(_keyLastPage5to10, page);
    }
  }

  // Per-schedule: last query (optional convenience)
  String? get lastScheduleQuery5to10 => _safePrefs.getString(_keyLastQuery5to10);

  Future<void> setLastScheduleQuery5to10(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _safePrefs.remove(_keyLastQuery5to10);
    } else {
      await _safePrefs.setString(_keyLastQuery5to10, value);
    }
  }

  // Clear all preferences
  Future<void> clearAllPreferences() async {
    await _safePrefs.clear();
  }
} 