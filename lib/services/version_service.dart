// Copyright Luka Löhr 2025

import 'package:package_info_plus/package_info_plus.dart';
import '../data/preferences_manager.dart';

class VersionService {
  final PreferencesManager _preferencesManager;
  
  VersionService(this._preferencesManager);
  
  /// Checks if the AI upgrade screen should be shown for authenticated users opening v1.7.0 for the first time
  /// Returns true if the AI upgrade screen should be displayed
  Future<bool> shouldShowAiUpgradePrompt() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final isAuthenticated = _preferencesManager.isAuthenticated;
      final isFirstLaunch = _preferencesManager.isFirstLaunch;
      final isUsingAiVersion = _preferencesManager.useAiVersion;
      final promptAlreadyShown = _preferencesManager.aiUpgradePromptShown;
      
      // Simple logic: Show AI upgrade prompt if:
      // 1. This is v1.7.0
      // 2. User is authenticated (has used the app before)
      // 3. Not a first launch (they've been through onboarding)
      // 4. Not already using AI version
      // 5. Haven't shown the prompt before
      return currentVersion == '1.7.0' && 
             isAuthenticated && 
             !isFirstLaunch && 
             !isUsingAiVersion && 
             !promptAlreadyShown;
      
          } catch (e) {
        // In case of any error, don't show the prompt
        return false;
      }
  }
  

} 