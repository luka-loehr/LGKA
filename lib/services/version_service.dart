// Copyright Luka Löhr 2025

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/preferences_manager.dart';

class VersionService {
  final PreferencesManager _preferencesManager;
  
  VersionService(this._preferencesManager);
  
  /// Checks if the app was updated and determines if the AI upgrade screen should be shown
  /// Returns true if the AI upgrade screen should be displayed
  Future<bool> shouldShowAiUpgradePrompt() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final lastVersion = _preferencesManager.lastAppVersion;
      final isUsingAiVersion = _preferencesManager.useAiVersion;
      
      // Debug logging
      debugPrint('🔍 VersionService Debug:');
      debugPrint('  Current version: $currentVersion');
      debugPrint('  Last stored version: $lastVersion');
      debugPrint('  Is using AI version: $isUsingAiVersion');
      
      // Special case for testing: if this is a fresh install of 1.7.0 and user is not using AI version,
      // treat it as an upgrade from 1.6.0 for testing purposes
      if (lastVersion == null && currentVersion == '1.7.0' && !isUsingAiVersion) {
        debugPrint('  🧪 Testing scenario: treating fresh 1.7.0 install as upgrade from 1.6.0');
        await _preferencesManager.setLastAppVersion('1.6.0'); // Set it as if upgrading from 1.6.0
        debugPrint('  ✅ Should show AI upgrade prompt: true (testing scenario)');
        return true;
      }
      
      // Update the stored version for future checks
      await _preferencesManager.setLastAppVersion(currentVersion);
      debugPrint('  Updated stored version to: $currentVersion');
      
      // If no previous version stored, this is first install - don't show prompt
      if (lastVersion == null) {
        debugPrint('  ❌ No previous version stored - first install');
        return false;
      }
      
      // If user is already using AI version, don't show prompt
      if (isUsingAiVersion) {
        debugPrint('  ❌ User already using AI version');
        return false;
      }
      
      // Check if updating from 1.6.0 to 1.7.0
      final isUpdatingFrom160 = lastVersion == '1.6.0';
      final isUpdatingTo170 = currentVersion == '1.7.0';
      
      debugPrint('  Is updating from 1.6.0: $isUpdatingFrom160');
      debugPrint('  Is updating to 1.7.0: $isUpdatingTo170');
      
      final shouldShow = isUpdatingFrom160 && isUpdatingTo170;
      debugPrint('  ✅ Should show AI upgrade prompt: $shouldShow');
      
      return shouldShow;
      
    } catch (e) {
      debugPrint('  ❌ Error in version check: $e');
      // In case of any error, don't show the prompt
      return false;
    }
  }
  
  /// Updates the stored app version to the current version
  Future<void> updateStoredVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      await _preferencesManager.setLastAppVersion(packageInfo.version);
    } catch (e) {
      // Silent failure - not critical
    }
  }
} 