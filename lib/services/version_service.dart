// Copyright Luka Löhr 2025

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
      final promptAlreadyShown = _preferencesManager.aiUpgradePromptShown;
      
      // If prompt was already shown, don't show it again
      if (promptAlreadyShown) {
        return false;
      }
      
      // Update the stored version for future checks
      await _preferencesManager.setLastAppVersion(currentVersion);
      
      // If no previous version stored, this is first install - don't show prompt
      if (lastVersion == null) {
        return false;
      }
      
      // If user is already using AI version, don't show prompt
      if (isUsingAiVersion) {
        return false;
      }
      
      // Check if updating from 1.6.0 to 1.7.0
      final isUpdatingFrom160 = lastVersion == '1.6.0';
      final isUpdatingTo170 = currentVersion == '1.7.0';
      
      return isUpdatingFrom160 && isUpdatingTo170;
      
    } catch (e) {
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