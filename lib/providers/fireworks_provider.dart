// Copyright Luka Löhr 2026

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

/// Provider that manages fireworks display state
final fireworksProvider = NotifierProvider<FireworksNotifier, bool>(FireworksNotifier.new);

/// Notifier that checks if it's New Year's Day in German time
class FireworksNotifier extends Notifier<bool> {
  Timer? _checkTimer;
  
  @override
  bool build() {
    // Check initial state and start periodic checking after build completes
    final initialState = _isNewYearsDay();
    
    // Schedule the periodic check to start after build
    Future.microtask(() => _startChecking());
    
    return initialState;
  }

  /// Check if current time is New Year's Day (January 1st) in German timezone
  bool _isNewYearsDay() {
    try {
      final berlin = tz.getLocation('Europe/Berlin');
      final now = tz.TZDateTime.now(berlin);
      return now.month == 1 && now.day == 1;
    } catch (e) {
      final now = DateTime.now();
      return now.month == 1 && now.day == 1;
    }
  }

  /// Start checking periodically if it's New Year's Day
  void _startChecking() {
    _checkTimer?.cancel();
    
    // Check every minute to catch the transition to New Year's Day
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkNewYearsDay();
    });
  }

  /// Check if it's New Year's Day and update state accordingly
  void _checkNewYearsDay() {
    final isNewYear = _isNewYearsDay();
    
    if (isNewYear != state) {
      // State changed - update it
      state = isNewYear;
    }
  }

  /// Cleanup when provider is disposed
  void cleanup() {
    _checkTimer?.cancel();
  }
}

