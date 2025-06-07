// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../data/preferences_manager.dart';

/// Service to manage app reviews based on user interactions.
class ReviewService {
  static const int _reviewThreshold = 20;
  
  final PreferencesManager _preferencesManager;
  final InAppReview _inAppReview = InAppReview.instance;
  
  ReviewService(this._preferencesManager);
  
  /// Tracks PDF opening and potentially triggers a review request.
  /// 
  /// Returns true if a review was requested, false otherwise.
  Future<bool> trackPlanOpenAndRequestReviewIfNeeded() async {
    // Skip if review was already requested
    if (_preferencesManager.hasRequestedReview) {
      return false;
    }
    
    // Increment the open count
    await _preferencesManager.incrementPlanOpenCount();
    final currentCount = _preferencesManager.planOpenCount;
    
    // If threshold is reached, try to show review dialog
    if (currentCount >= _reviewThreshold) {
      return await _requestReview();
    }
    
    return false;
  }
  
  /// Requests an in-app review.
  /// 
  /// Returns true if review was requested, false otherwise.
  Future<bool> _requestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        // Mark as requested before showing dialog to avoid potential race conditions
        await _preferencesManager.setHasRequestedReview(true);
        
        // Request the review
        await _inAppReview.requestReview();
        return true;
      } else {
        // Not available but still mark as requested to avoid future attempts
        await _preferencesManager.setHasRequestedReview(true);
        debugPrint('In-app review not available on this device.');
        return false;
      }
    } catch (e) {
      // Mark as requested to avoid repeated failures
      await _preferencesManager.setHasRequestedReview(true);
      debugPrint('Error requesting review: $e');
      return false;
    }
  }
} 