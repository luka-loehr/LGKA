// Copyright Luka Löhr 2026

class ParserSchemaException implements Exception {
  ParserSchemaException(this.message);

  final String message;

  @override
  String toString() => 'ParserSchemaException: $message';
}

class ParserChangeTracker {
  final Map<String, String> _fingerprints = {};

  bool didShapeChange({required String key, required String fingerprint}) {
    final previous = _fingerprints[key];
    _fingerprints[key] = fingerprint;
    return previous != null && previous != fingerprint;
  }
}

class ParserGuard {
  static String buildFingerprint(Map<String, Object?> metrics) {
    final entries = metrics.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((entry) => '${entry.key}=${entry.value ?? 'null'}')
        .join('|');
  }

  static void requireMin({
    required String parser,
    required String field,
    required int actual,
    required int min,
  }) {
    if (actual < min) {
      throw ParserSchemaException(
        '$parser expected at least $min $field value(s), got $actual',
      );
    }
  }
}
