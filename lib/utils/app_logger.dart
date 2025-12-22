// Copyright Luka Löhr 2025

import 'package:flutter/foundation.dart';

/// Centralized logging system for the LGKA app
class AppLogger {
  static const String _appName = 'LGKA';
  static const String _developer = 'Luka Löhr';

  /// Print startup message
  static void welcome() {
    debugPrint('$_appName - Made by $_developer');
    debugPrint('Initializing app...');
  }

  /// General info logs
  static void info(String message, {String? module}) {
    final prefix = module != null ? '[INFO][$module]' : '[INFO]';
    _log(prefix, message);
  }

  /// Success logs
  static void success(String message, {String? module}) {
    final prefix = module != null ? '[OK][$module]' : '[OK]';
    _log(prefix, message);
  }

  /// Warning logs
  static void warning(String message, {String? module}) {
    final prefix = module != null ? '[WARN][$module]' : '[WARN]';
    _log(prefix, message);
  }

  /// Error logs
  static void error(String message,
      {String? module, Object? error, StackTrace? stackTrace}) {
    final prefix = module != null ? '[ERROR][$module]' : '[ERROR]';
    _log(prefix, message);

    if (error != null) {
      _log(prefix, 'Error: $error');
    }

    if (stackTrace != null) {
      _log(prefix, 'Stack trace: $stackTrace');
    }
  }

  /// Debug logs (only in debug mode)
  static void debug(String message, {String? module}) {
    if (kDebugMode) {
      final prefix = module != null ? '[DEBUG][$module]' : '[DEBUG]';
      _log(prefix, message);
    }
  }

  /// Weather service specific logs
  static void weather(String message) {
    _log('[Weather]', message);
  }

  /// PDF/Repository specific logs
  static void pdf(String message) {
    _log('[PDF]', message);
  }

  /// Schedule service specific logs
  static void schedule(String message) {
    _log('[Schedule]', message);
  }

  /// UI/Navigation specific logs
  static void navigation(String message) {
    _log('[Navigation]', message);
  }

  /// Chart/Visualization specific logs
  static void chart(String message) {
    _log('[Chart]', message);
  }

  /// Search specific logs
  static void search(String message) {
    _log('[Search]', message);
  }

  /// Initialization logs
  static void init(String message, {String? module}) {
    final prefix = module != null ? '[INIT][$module]' : '[INIT]';
    _log(prefix, message);
  }

  /// Network request logs
  static void network(String message, {String? module}) {
    final prefix = module != null ? '[Network][$module]' : '[Network]';
    _log(prefix, message);
  }

  /// Data processing logs
  static void data(String message) {
    _log('[Data]', message);
  }

  /// Core logging method
  static void _log(String prefix, String message) {
    debugPrint('$prefix $message');
  }
}
