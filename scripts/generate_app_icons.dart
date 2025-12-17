#!/usr/bin/env dart

// Script to generate app icons from your static logo file
// 
// Usage:
// 1. Place your app-logo.png (with background) in assets/images/app-icons/
// 2. Run: dart run generate_app_icons.dart
// 
// This will automatically generate all required app icon sizes for Android and iOS
// using adaptive icons with proper legacy support for better compatibility.

import 'dart:io';

void main() async {
  print('LGKA App Icon Generator');
  print('=' * 50);
  
  // Check if logo file exists
  final logoFile = File('assets/images/app-icons/app-logo.png');
  if (!logoFile.existsSync()) {
    print('[ERROR] app-logo.png not found!');
    print('        Please place your logo at:');
    print('        assets/images/app-icons/app-logo.png');
    print('');
    print('Logo Requirements:');
    print('  - PNG format (with integrated background)');
    print('  - 1024x1024px minimum size');
    print('  - Include your own background design');
    print('  - Should look good at small sizes');
    print('  - Keep important elements in center area');
    exit(1);
  }
  
  print('[OK] Found app-logo.png');
  
  // Check if flutter_launcher_icons is installed
  print('[INFO] Getting dependencies...');
  final pubGetResult = await Process.run('flutter', ['pub', 'get']);
  if (pubGetResult.exitCode != 0) {
    print('[ERROR] Failed to run flutter pub get');
    print(pubGetResult.stderr);
    exit(1);
  }
  
  print('[INFO] Generating adaptive app icons...');
  final iconResult = await Process.run(
    'dart', 
    ['run', 'flutter_launcher_icons'],
    workingDirectory: Directory.current.path,
  );
  
  if (iconResult.exitCode == 0) {
    print('[OK] Adaptive app icons generated successfully!');
    print('');
    print('Generated icons for:');
    print('  - Android adaptive icons (foreground + background)');
    print('  - Android legacy icons (for app info compatibility)');
    print('  - All required densities (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)');
    print('  - Your logo background is preserved');
    print('');
    print('Next steps:');
    print('  1. Run "flutter clean"');
    print('  2. Build and test your app');
    print('');
    print('Icon behavior:');
    print('  - Home screen: Uses adaptive icon with 16% inset');
    print('  - App info screen: Uses legacy icon at full size');
    print('  - Both display your logo properly sized');
  } else {
    print('[ERROR] Failed to generate icons');
    print('Output: ${iconResult.stdout}');
    print('Error: ${iconResult.stderr}');
    exit(1);
  }
}
