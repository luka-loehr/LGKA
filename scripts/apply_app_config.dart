#!/usr/bin/env dart

import 'dart:io';
import 'package:yaml/yaml.dart';

void main() async {
  print('Applying centralized app configuration...\n');

  try {
    // Read the centralized configuration
    final configFile = File('app_config/app_config.yaml');
    if (!configFile.existsSync()) {
      print('[ERROR] app_config/app_config.yaml not found');
      exit(1);
    }

    final configContent = await configFile.readAsString();
    final config = loadYaml(configContent);

    // Read version from pubspec.yaml (single source of truth)
    final versionInfo = await getVersionFromPubspec();
    final configWithVersion = Map.from(config);
    configWithVersion['version_name'] = versionInfo['version_name'];
    configWithVersion['version_code'] = versionInfo['version_code'];

    print('[INFO] Using version from pubspec.yaml: ${versionInfo['version_name']}+${versionInfo['version_code']}');

    // Apply configuration to all platforms
    await updateAndroidConfig(configWithVersion);
    await updateiOSConfig(configWithVersion);
    await updateFlutterLauncherIcons(configWithVersion);

    print('\n[OK] App configuration applied successfully!');
    print('\nNext steps:');
    print('1. Run: flutter pub get');
    print('2. Run: dart run flutter_launcher_icons');
    print('3. Rebuild your app');

  } catch (e) {
    print('[ERROR] Error applying configuration: $e');
    exit(1);
  }
}

Future<Map<String, String>> getVersionFromPubspec() async {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    throw Exception('pubspec.yaml not found');
  }

  final content = await pubspecFile.readAsString();
  final pubspec = loadYaml(content);

  final versionString = pubspec['version'] as String;
  final versionParts = versionString.split('+');

  if (versionParts.length != 2) {
    throw Exception('Invalid version format in pubspec.yaml. Expected format: "1.0.0+1"');
  }

  return {
    'version_name': versionParts[0],
    'version_code': versionParts[1],
  };
}

Future<void> updatePubspecDescription(Map config) async {
  print('[INFO] Updating pubspec.yaml description...');

  final pubspecFile = File('pubspec.yaml');
  final content = await pubspecFile.readAsString();

  // Only update description, version is managed directly in pubspec.yaml
  final updatedContent = content.replaceAll(
    RegExp(r'description:\s+"[^"]*"'),
    'description: "${config['app_description']}"'
  );

  await pubspecFile.writeAsString(updatedContent);
  print('       Description updated (version managed directly in pubspec.yaml)');
}

Future<void> updateAndroidConfig(Map config) async {
  print('[Android] Updating configuration...');
  
  // Update build.gradle.kts
  final buildGradleFile = File('android/app/build.gradle.kts');
  if (buildGradleFile.existsSync()) {
    final content = await buildGradleFile.readAsString();
    final updatedContent = content
        .replaceAll(
          RegExp(r'applicationId\s*=\s*"[^"]*"'),
          'applicationId = "${config['package_name']}"'
        )
        .replaceAll(
          RegExp(r'namespace\s*=\s*"[^"]*"'),
          'namespace = "${config['package_name']}"'
        );
    
    await buildGradleFile.writeAsString(updatedContent);
    print('         Package name updated');
  }

  // Update AndroidManifest.xml
  final manifestFile = File('android/app/src/main/AndroidManifest.xml');
  if (manifestFile.existsSync()) {
    final content = await manifestFile.readAsString();
    final updatedContent = content.replaceAll(
      RegExp(r'android:label="[^"]*"'),
      'android:label="${config['app_name']}"'
    );
    
    await manifestFile.writeAsString(updatedContent);
    print('         App name updated in manifest');
  }
}

Future<void> updateiOSConfig(Map config) async {
  print('[iOS] Updating configuration...');
  
  // Update app_config.xcconfig
  final xconfigFile = File('ios/Runner/app_config.xcconfig');
  final xconfigContent = '''// App Configuration
// This file contains app-specific configuration that can be easily modified
APP_DISPLAY_NAME = ${config['app_name']}
''';
  
  await xconfigFile.writeAsString(xconfigContent);
  print('      App name updated');

  // Update Info.plist bundle identifier reference (already uses variables)
  print('      Info.plist already configured for dynamic values');
}

Future<void> updateFlutterLauncherIcons(Map config) async {
  print('[Icons] Updating launcher icons configuration...');
  
  // Update pubspec.yaml with new icon path
  final pubspecFile = File('pubspec.yaml');
  final content = await pubspecFile.readAsString();
  
  final iconSection = '''
# Flutter Launcher Icons Configuration
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "${config['app_icon_path']}"
  # Using static logo with integrated background - no adaptive icons needed
  # adaptive_icon_background: "assets/images/app-icons/app-logo-adaptive-background.png"
  # adaptive_icon_foreground: "assets/images/app-icons/app-logo-adaptive-foreground.png"
  # Uncomment and customize these if needed:
  # min_sdk_android: 21
  # remove_alpha_ios: true''';

  // Replace the existing flutter_launcher_icons section
  final updatedContent = content.replaceAll(
    RegExp(r'# Flutter Launcher Icons Configuration[\s\S]*?# remove_alpha_ios: true', multiLine: true),
    iconSection.trim()
  );
  
  await pubspecFile.writeAsString(updatedContent);
  print('        Icon path updated to ${config['app_icon_path']}');
}
