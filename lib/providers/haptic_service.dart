// Copyright Luka Löhr 2025

import 'package:flutter/services.dart';

/// A service for managing haptic feedback
class HapticService {
  /// Provides light haptic feedback
  /// Used for subtle interactions and confirmations
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Provides medium haptic feedback
  /// Used for standard interactions and button presses
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Provides intense haptic feedback
  /// Used for important actions and significant events
  static Future<void> intense() async {
    await HapticFeedback.heavyImpact();
  }
}
