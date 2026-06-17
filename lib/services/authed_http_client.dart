// Copyright Luka Löhr 2026

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_credentials.dart';
import '../utils/app_info.dart';

/// Shared HTTP helper for the school's HTTP-Basic-Auth-protected endpoints
/// (schedule + substitution PDFs).
///
/// Centralises the credential encoding, `User-Agent`, and default timeout that
/// were previously copy-pasted across the data services. The Basic credential
/// is computed once and reused.
class AuthedHttpClient {
  AuthedHttpClient._();

  /// Default request timeout shared across schedule/substitution requests.
  static const Duration defaultTimeout = Duration(seconds: 10);

  static final String _authHeader = 'Basic '
      '${base64Encode(utf8.encode('${AppCredentials.username}:${AppCredentials.password}'))}';

  static Map<String, String> get _headers => {
        'Authorization': _authHeader,
        'User-Agent': AppInfo.userAgent,
      };

  /// Authenticated GET with the standard headers and timeout.
  static Future<http.Response> get(Uri uri, {Duration? timeout}) =>
      http.get(uri, headers: _headers).timeout(timeout ?? defaultTimeout);

  /// Authenticated HEAD with the standard headers and timeout.
  static Future<http.Response> head(Uri uri, {Duration? timeout}) =>
      http.head(uri, headers: _headers).timeout(timeout ?? defaultTimeout);
}
