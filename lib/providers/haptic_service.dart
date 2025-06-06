// Copyright Luka Löhr 2025

import 'package:flutter/services.dart';

/// A service for managing haptic feedback with premium, minimalistic patterns
class HapticService {
  /// Provides a subtle, gentle feedback for standard interactions
  /// Perfect for successful actions and confirmations
  static Future<void> subtle() async {
    // Light impact is the most subtle feedback available
    await HapticFeedback.selectionClick();
  }

  /// Provides a light feedback for interactions
  /// Used for button presses and navigation
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }
  
  /// Provides a medium feedback for more significant interactions
  /// Used for completing actions or success states
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }
  
  /// Provides premium success feedback
  /// Perfect for confirming successful operations
  static Future<void> success() async {
    // A more premium pattern: subtle, then a slight pause, then light
    await subtle();
    await Future.delayed(const Duration(milliseconds: 40));
    await light();
  }

  /// Provides error feedback that feels premium but noticeable
  static Future<void> error() async {
    // Single sharp feedback for errors - more minimalistic approach
    await HapticFeedback.mediumImpact();
  }
} 