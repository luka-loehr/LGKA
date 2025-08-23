// Copyright Luka Löhr 2025

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesManager extends ChangeNotifier {
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyAuthenticated = 'is_authenticated';
  static const String _keyDebugMode = 'is_debug_mode';
  static const String _keyShowNavigationDebug = 'show_navigation_debug';
  static const String _keyAccentColor = 'accent_color';
  static const String _keyVibrationEnabled = 'vibration_enabled';

  late final SharedPreferences _prefs;

  // Initialize the preferences manager
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
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

  // Clear all preferences
  Future<void> clearAllPreferences() async {
    await _prefs.clear();
    notifyListeners();
  }
} 