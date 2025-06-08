#!/usr/bin/env dart

import 'dart:io';
import 'package:yaml/yaml.dart';

void main() async {
  print('🚀 Applying centralized app configuration...\n');

  try {
    // Read the centralized configuration
    final configFile = File('app_config/app_config.yaml');
    if (!configFile.existsSync()) {
      print('❌ Error: app_config/app_config.yaml not found');
      exit(1);
    }

    final configContent = await configFile.readAsString();
    final config = loadYaml(configContent);

    // Apply configuration to all platforms
    await updatePubspecYaml(config);
    await updateAndroidConfig(config);
    await updateiOSConfig(config);
    await updateFlutterLauncherIcons(config);

    print('\n✅ App configuration applied successfully!');
    print('\nNext steps:');
    print('1. Run: flutter pub get');
    print('2. Run: dart run flutter_launcher_icons');
    print('3. Rebuild your app');

  } catch (e) {
    print('❌ Error applying configuration: $e');
    exit(1);
  }
}

Future<void> updatePubspecYaml(Map config) async {
  print('📝 Updating pubspec.yaml...');
  
  final pubspecFile = File('pubspec.yaml');
  final content = await pubspecFile.readAsString();
  
  // Update version
  final version = '${config['version_name']}+${config['version_code']}';
  final updatedContent = content.replaceAll(
    RegExp(r'version:\s+[\d\.]+\+\d+'),
    'version: $version'
  ).replaceAll(
    RegExp(r'description:\s+"[^"]*"'),
    'description: "${config['app_description']}"'
  );
  
  await pubspecFile.writeAsString(updatedContent);
  print('   ✓ Version updated to $version');
  print('   ✓ Description updated');
}

Future<void> updateAndroidConfig(Map config) async {
  print('🤖 Updating Android configuration...');
  
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
    print('   ✓ Package name updated');
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
    print('   ✓ App name updated in manifest');
  }
}

Future<void> updateiOSConfig(Map config) async {
  print('🍎 Updating iOS configuration...');
  
  // Update app_config.xcconfig
  final xconfigFile = File('ios/Runner/app_config.xcconfig');
  final xconfigContent = '''// App Configuration
// This file contains app-specific configuration that can be easily modified
APP_DISPLAY_NAME = ${config['app_name']}
''';
  
  await xconfigFile.writeAsString(xconfigContent);
  print('   ✓ iOS app name updated');

  // Update Info.plist bundle identifier reference (already uses variables)
  print('   ✓ iOS Info.plist already configured for dynamic values');
}

Future<void> updateFlutterLauncherIcons(Map config) async {
  print('🎨 Updating launcher icons configuration...');
  
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
  print('   ✓ Icon path updated to ${config['app_icon_path']}');
} 