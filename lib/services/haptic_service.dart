// Copyright Luka Löhr 2025

import 'package:flutter/services.dart';

/// A service for managing haptic feedback
class HapticService {
  /// Provides light haptic feedback
  /// Used for subtle interactions and confirmations
  /// Uses selectionClick for a subtle, distinct feel
  static Future<void> light() async {
    await HapticFeedback.selectionClick();
  }

  /// Provides medium haptic feedback
  /// Used for standard interactions and button presses
  /// Uses mediumImpact for a standard vibration
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Provides intense haptic feedback
  /// Used for important actions and significant events
  /// Uses a pattern of heavy impacts to create a distinct, intense vibration
  static Future<void> intense() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
  }
}
