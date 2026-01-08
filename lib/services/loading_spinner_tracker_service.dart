// Copyright Luka Löhr 2026

import 'haptic_service.dart';

/// A service for tracking loading spinner visibility and triggering haptic feedback
/// only when spinners are actually displayed to users.
/// 
/// This ensures haptic feedback is only provided when users experience a visible
/// loading state, avoiding unnecessary feedback for instant page loads.
class LoadingSpinnerTracker {
  bool _wasSpinnerVisible = false;
  bool _hadDataPreviously = false;
  bool _hapticScheduled = false;
  DateTime? _spinnerShowTime;
  
  /// Minimum duration (in milliseconds) that a spinner must be visible
  /// before haptic feedback is triggered when it disappears.
  /// This prevents haptic feedback for very brief loading states.
  static const int minimumSpinnerDurationMs = 100;

  /// Track the current state and trigger haptic feedback if appropriate.
  /// 
  /// Parameters:
  /// - [isSpinnerVisible]: Whether a loading spinner is currently visible
  /// - [hasData]: Whether data has been successfully loaded
  /// - [hasError]: Whether an error occurred during loading
  /// - [mounted]: Whether the widget is still mounted (for safety)
  /// 
  /// Returns true if haptic feedback was triggered, false otherwise.
  bool trackState({
    required bool isSpinnerVisible,
    required bool hasData,
    required bool hasError,
    required bool mounted,
  }) {
    bool hapticTriggered = false;

    // Track when spinner becomes visible
    if (isSpinnerVisible && !_wasSpinnerVisible) {
      _spinnerShowTime = DateTime.now();
    }

    // Trigger haptic when transitioning from spinner visible to data loaded
    // Only trigger if:
    // 1. Spinner was previously visible
    // 2. Spinner is no longer visible
    // 3. No error occurred
    // 4. Data is now available
    // 5. We didn't have data previously (real load, not cache check)
    // 6. Haptic hasn't been scheduled yet
    // 7. Spinner was visible for minimum duration
    if (_wasSpinnerVisible && 
        !isSpinnerVisible && 
        !hasError && 
        hasData && 
        !_hadDataPreviously && 
        !_hapticScheduled &&
        _wasSpinnerVisibleLongEnough()) {
      _hapticScheduled = true;
      
      // Trigger haptic feedback asynchronously
      Future.microtask(() {
        if (mounted) {
          HapticService.medium();
        }
      });
      
      hapticTriggered = true;
    }

    // Reset haptic flag when loading starts again or error occurs
    if (isSpinnerVisible || hasError) {
      _hapticScheduled = false;
    }

    // Track state for next call
    _wasSpinnerVisible = isSpinnerVisible;
    _hadDataPreviously = hasData;

    return hapticTriggered;
  }

  /// Check if the spinner was visible for the minimum required duration
  bool _wasSpinnerVisibleLongEnough() {
    if (_spinnerShowTime == null) return false;
    
    final duration = DateTime.now().difference(_spinnerShowTime!);
    return duration.inMilliseconds >= minimumSpinnerDurationMs;
  }

  /// Reset the tracker state (useful when navigating away or reinitializing)
  void reset() {
    _wasSpinnerVisible = false;
    _hadDataPreviously = false;
    _hapticScheduled = false;
    _spinnerShowTime = null;
  }

  /// Get whether a spinner is currently being tracked as visible
  bool get isSpinnerVisible => _wasSpinnerVisible;

  /// Get whether haptic feedback has been scheduled
  bool get isHapticScheduled => _hapticScheduled;
}

