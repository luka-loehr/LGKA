#!/usr/bin/env dart

// Script to generate app icons from your static logo file
// 
// Usage:
// 1. Place your app-logo.png (with background) in assets/images/app-icons/
// 2. Run: dart run generate_app_icons.dart
// 
// This will automatically generate all required app icon sizes for Android and iOS
// using your static logo with its integrated background.

import 'dart:io';
import 'package:flutter/foundation.dart';

void main() async {
  debugPrint('🎯 LGKA Static App Icon Generator');
  debugPrint('=' * 50);
  
  // Check if logo file exists
  final logoFile = File('assets/images/app-icons/app-logo.png');
  if (!logoFile.existsSync()) {
    debugPrint('❌ Error: app-logo.png not found!');
    debugPrint('   Please place your logo at:');
    debugPrint('   assets/images/app-icons/app-logo.png');
    debugPrint('');
    debugPrint('📋 Logo Requirements:');
    debugPrint('   • PNG format (with or without transparency)');
    debugPrint('   • 1024x1024px minimum size');
    debugPrint('   • Include your own background design');
    debugPrint('   • Should look good at small sizes');
    debugPrint('   • Keep important elements in center 80% of image');
    exit(1);
  }
  
  debugPrint('✅ Found app-logo.png');
  
  // Check if flutter_launcher_icons is installed
  debugPrint('📦 Installing flutter_launcher_icons...');
  final pubGetResult = await Process.run('flutter', ['pub', 'get']);
  if (pubGetResult.exitCode != 0) {
    debugPrint('❌ Failed to run flutter pub get');
    debugPrint(pubGetResult.stderr);
    exit(1);
  }
  
  debugPrint('🔨 Generating static app icons...');
  final iconResult = await Process.run(
    'dart', 
    ['run', 'flutter_launcher_icons:main'],
    workingDirectory: Directory.current.path,
  );
  
  if (iconResult.exitCode == 0) {
    debugPrint('✅ Static app icons generated successfully!');
    debugPrint('');
    debugPrint('📱 Generated icons for:');
    debugPrint('   • Android (all densities) - static icons');
    debugPrint('   • iOS (all required sizes)');
    debugPrint('   • Your logo background is preserved');
    debugPrint('');
    debugPrint('🚀 Next steps:');
    debugPrint('   1. Run "flutter clean"');
    debugPrint('   2. Run "flutter pub get"');
    debugPrint('   3. Test your app to see the new icon');
    debugPrint('');
    debugPrint('📝 Note: Your logo will appear exactly as designed');
    debugPrint('   with its integrated background on all devices.');
  } else {
    debugPrint('❌ Failed to generate icons');
    debugPrint('Output: ${iconResult.stdout}');
    debugPrint('Error: ${iconResult.stderr}');
    exit(1);
  }
} 