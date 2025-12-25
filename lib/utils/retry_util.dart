// Copyright Luka Löhr 2025

import 'dart:async';
import '../utils/app_logger.dart';

/// Utility class for automatic retry logic
class RetryUtil {
  /// Retry a function up to [maxRetries] times (total attempts = maxRetries + 1)
  /// Returns the result of the function if successful, or throws the last error
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxRetries = 2,
    Duration delay = const Duration(milliseconds: 500),
    String? operationName,
    bool Function(Object error)? shouldRetry,
  }) async {
    int attempt = 0;
    Object? lastError;
    StackTrace? lastStackTrace;

    while (attempt <= maxRetries) {
      try {
        final result = await operation();
        if (attempt > 0) {
          AppLogger.info(
            'Operation succeeded on attempt ${attempt + 1}',
            module: operationName ?? 'RetryUtil',
          );
        }
        return result;
      } catch (e, stackTrace) {
        lastError = e;
        lastStackTrace = stackTrace;

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(e)) {
          // Don't retry for this type of error
          rethrow;
        }

        // Check if we've exhausted retries
        if (attempt >= maxRetries) {
          AppLogger.warning(
            'Operation failed after ${attempt + 1} attempts',
            module: operationName ?? 'RetryUtil',
          );
          break;
        }

        attempt++;
        AppLogger.debug(
          'Retrying operation (attempt ${attempt + 1}/${maxRetries + 1}): $e',
          module: operationName ?? 'RetryUtil',
        );

        // Wait before retrying
        await Future.delayed(delay);
      }
    }

    // If we get here, all retries failed
    if (lastError != null) {
      Error.throwWithStackTrace(lastError, lastStackTrace ?? StackTrace.current);
    }
    throw StateError('Retry failed but no error was captured');
  }

  /// Check if an error is retryable (network/timeout errors)
  static bool isRetryableError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
        errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection reset');
  }
}



