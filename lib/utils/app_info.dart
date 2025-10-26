// Copyright Luka Löhr 2025

import 'package:package_info_plus/package_info_plus.dart';

/// Utility class for accessing app information
class AppInfo {
  static PackageInfo? _packageInfo;
  
  /// Initialize app info (call this in main)
  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }
  
  /// Get app version (e.g., "2.2.6")
  static String get version => _packageInfo?.version ?? 'unknown';
  
  /// Get build number (e.g., "158")
  static String get buildNumber => _packageInfo?.buildNumber ?? 'unknown';
  
  /// Get full version string (e.g., "2.2.6+158")
  static String get fullVersion => '${version}+${buildNumber}';
  
  /// Get User-Agent header value
  static String get userAgent => 'LGKA-App-Luka-Loehr/$version';
}

