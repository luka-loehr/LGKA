import 'package:flutter_test/flutter_test.dart';
import 'package:lgka_flutter/utils/parser_guard.dart';

void main() {
  test('buildFingerprint is stable regardless of map insertion order', () {
    final a = ParserGuard.buildFingerprint({'b': 2, 'a': 1});
    final b = ParserGuard.buildFingerprint({'a': 1, 'b': 2});

    expect(a, b);
  });

  test('change tracker only reports changes after first observation', () {
    final tracker = ParserChangeTracker();
    const key = 'news:list';

    final first = tracker.didShapeChange(key: key, fingerprint: 'a=1|b=2');
    final second = tracker.didShapeChange(key: key, fingerprint: 'a=1|b=2');
    final third = tracker.didShapeChange(key: key, fingerprint: 'a=1|b=3');

    expect(first, isFalse);
    expect(second, isFalse);
    expect(third, isTrue);
  });

  test(
    'requireMin throws ParserSchemaException for missing required shape',
    () {
      expect(
        () => ParserGuard.requireMin(
          parser: 'Schedule parser',
          field: 'links',
          actual: 0,
          min: 1,
        ),
        throwsA(isA<ParserSchemaException>()),
      );
    },
  );
}
