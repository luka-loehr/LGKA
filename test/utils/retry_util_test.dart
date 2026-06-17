import 'package:flutter_test/flutter_test.dart';
import 'package:lgka_flutter/utils/retry_util.dart';

class _NetworkError implements Exception {
  @override
  String toString() => 'Socket timeout while connecting';
}

class _ValidationError implements Exception {
  @override
  String toString() => 'Validation failed';
}

void main() {
  test('retries until success within max retries', () async {
    var attempts = 0;

    final result = await RetryUtil.retry<int>(
      maxRetries: 3,
      delay: Duration.zero,
      operation: () async {
        attempts++;
        if (attempts < 3) {
          throw _NetworkError();
        }
        return 42;
      },
    );

    expect(result, 42);
    expect(attempts, 3);
  });

  test('rethrows immediately when shouldRetry blocks retries', () async {
    var attempts = 0;

    await expectLater(
      RetryUtil.retry<void>(
        maxRetries: 3,
        delay: Duration.zero,
        shouldRetry: (_) => false,
        operation: () async {
          attempts++;
          throw _ValidationError();
        },
      ),
      throwsA(isA<_ValidationError>()),
    );

    expect(attempts, 1);
  });

  test('classifies retryable network-like errors', () {
    expect(RetryUtil.isRetryableError(_NetworkError()), isTrue);
    expect(RetryUtil.isRetryableError(_ValidationError()), isFalse);
  });
}
