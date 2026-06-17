// Copyright Luka Löhr 2026

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/preferences_manager.dart';

/// State class for preferences manager
class PreferencesManagerState {
  final bool isInitialized;
  final bool isFirstLaunch;
  final bool isAuthenticated;
  final bool onboardingCompleted;
  final String accentColor;
  final String themeMode;
  final bool vibrationEnabled;
  final bool krankmeldungInfoShown;
  final int? lastSchedulePage5to10;
  final String? lastScheduleQuery5to10;
  final String? selectedScheduleClass;

  const PreferencesManagerState({
    this.isInitialized = false,
    this.isFirstLaunch = true,
    this.isAuthenticated = false,
    this.onboardingCompleted = false,
    this.accentColor = 'blue',
    this.themeMode = 'system',
    this.vibrationEnabled = true,
    this.krankmeldungInfoShown = false,
    this.lastSchedulePage5to10,
    this.lastScheduleQuery5to10,
    this.selectedScheduleClass,
  });

  PreferencesManagerState copyWith({
    bool? isInitialized,
    bool? isFirstLaunch,
    bool? isAuthenticated,
    bool? onboardingCompleted,
    String? accentColor,
    String? themeMode,
    bool? vibrationEnabled,
    bool? krankmeldungInfoShown,
    int? lastSchedulePage5to10,
    String? lastScheduleQuery5to10,
    String? selectedScheduleClass,
  }) {
    return PreferencesManagerState(
      isInitialized: isInitialized ?? this.isInitialized,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      accentColor: accentColor ?? this.accentColor,
      themeMode: themeMode ?? this.themeMode,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      krankmeldungInfoShown: krankmeldungInfoShown ?? this.krankmeldungInfoShown,
      lastSchedulePage5to10: lastSchedulePage5to10 ?? this.lastSchedulePage5to10,
      lastScheduleQuery5to10: lastScheduleQuery5to10 ?? this.lastScheduleQuery5to10,
      selectedScheduleClass: selectedScheduleClass ?? this.selectedScheduleClass,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PreferencesManagerState &&
        other.isInitialized == isInitialized &&
        other.isFirstLaunch == isFirstLaunch &&
        other.isAuthenticated == isAuthenticated &&
        other.onboardingCompleted == onboardingCompleted &&
        other.accentColor == accentColor &&
        other.themeMode == themeMode &&
        other.vibrationEnabled == vibrationEnabled &&
        other.krankmeldungInfoShown == krankmeldungInfoShown &&
        other.lastSchedulePage5to10 == lastSchedulePage5to10 &&
        other.lastScheduleQuery5to10 == lastScheduleQuery5to10 &&
        other.selectedScheduleClass == selectedScheduleClass;
  }

  @override
  int get hashCode => Object.hash(
        isInitialized,
        isFirstLaunch,
        isAuthenticated,
        onboardingCompleted,
        accentColor,
        themeMode,
        vibrationEnabled,
        krankmeldungInfoShown,
        lastSchedulePage5to10,
        lastScheduleQuery5to10,
        selectedScheduleClass,
      );
}

/// Notifier for preferences manager
class PreferencesManagerNotifier extends Notifier<PreferencesManagerState> {
  PreferencesManagerNotifier([PreferencesManager? manager])
      : _manager = manager ?? PreferencesManager();

  final PreferencesManager _manager;

  @override
  PreferencesManagerState build() {
    if (_manager.isInitialized) {
      // Pre-initialized before runApp() — return correct state immediately,
      // no async gap, no theme flash.
      return _stateFromManager();
    }
    // Fallback: async init (should not normally be hit after main() pre-inits)
    Future.microtask(() async {
      await _manager.init();
      _refreshState();
    });
    return const PreferencesManagerState();
  }

  PreferencesManagerState _stateFromManager() {
    return PreferencesManagerState(
      isInitialized: _manager.isInitialized,
      isFirstLaunch: _manager.isFirstLaunch,
      isAuthenticated: _manager.isAuthenticated,
      onboardingCompleted: _manager.onboardingCompleted,
      accentColor: _manager.accentColor,
      themeMode: _manager.themeMode,
      vibrationEnabled: _manager.vibrationEnabled,
      krankmeldungInfoShown: _manager.krankmeldungInfoShown,
      lastSchedulePage5to10: _manager.lastSchedulePage5to10,
      lastScheduleQuery5to10: _manager.lastScheduleQuery5to10,
      selectedScheduleClass: _manager.selectedScheduleClass,
    );
  }

  Future<void> init() async {
    await _manager.init();
    _refreshState();
  }

  void _refreshState() {
    if (!_manager.isInitialized) return;
    state = _stateFromManager();
  }

  Future<void> setFirstLaunch(bool value) async {
    await _manager.setFirstLaunch(value);
    _refreshState();
  }

  Future<void> setAuthenticated(bool value) async {
    await _manager.setAuthenticated(value);
    _refreshState();
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _manager.setOnboardingCompleted(value);
    _refreshState();
  }

  Future<void> setAccentColor(String color) async {
    await _manager.setAccentColor(color);
    _refreshState();
  }

  Future<void> setThemeMode(String mode) async {
    await _manager.setThemeMode(mode);
    _refreshState();
  }

  Future<void> setVibrationEnabled(bool value) async {
    await _manager.setVibrationEnabled(value);
    _refreshState();
  }

  Future<void> setKrankmeldungInfoShown(bool value) async {
    await _manager.setKrankmeldungInfoShown(value);
    _refreshState();
  }

  Future<void> setLastSchedulePage5to10(int? page) async {
    await _manager.setLastSchedulePage5to10(page);
    _refreshState();
  }

  Future<void> setLastScheduleQuery5to10(String? value) async {
    await _manager.setLastScheduleQuery5to10(value);
    _refreshState();
  }

  Future<void> setSelectedScheduleClass(String? className) async {
    await _manager.setSelectedScheduleClass(className);
    _refreshState();
  }

  // Expose manager for direct access (for compatibility)
  PreferencesManager get manager => _manager;
}

// Preferences Manager Provider
final preferencesManagerProvider =
    NotifierProvider<PreferencesManagerNotifier, PreferencesManagerState>(
        PreferencesManagerNotifier.new);
