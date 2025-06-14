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

void main() async {
  print('🎯 LGKA Static App Icon Generator');
  print('=' * 50);
  
  // Check if logo file exists
  final logoFile = File('assets/images/app-icons/app-logo.png');
  if (!logoFile.existsSync()) {
    print('❌ Error: app-logo.png not found!');
    print('   Please place your logo at:');
    print('   assets/images/app-icons/app-logo.png');
    print('');
    print('📋 Logo Requirements:');
    print('   • PNG format (with or without transparency)');
    print('   • 1024x1024px minimum size');
    print('   • Include your own background design');
    print('   • Should look good at small sizes');
    print('   • Keep important elements in center 80% of image');
    exit(1);
  }
  
  print('✅ Found app-logo.png');
  
  // Check if flutter_launcher_icons is installed
  print('📦 Installing flutter_launcher_icons...');
  final pubGetResult = await Process.run('flutter', ['pub', 'get']);
  if (pubGetResult.exitCode != 0) {
    print('❌ Failed to run flutter pub get');
    print(pubGetResult.stderr);
    exit(1);
  }
  
  print('🔨 Generating static app icons...');
  final iconResult = await Process.run(
    'dart', 
    ['run', 'flutter_launcher_icons:main'],
    workingDirectory: Directory.current.path,
  );
  
  if (iconResult.exitCode == 0) {
    print('✅ Static app icons generated successfully!');
    
    // Copy icons to drawable folders that weren't updated
    print('📋 Copying icons to drawable folders...');
    final drawableFolders = [
      'android/app/src/main/res/drawable',
      'android/app/src/main/res/drawable-hdpi',
      'android/app/src/main/res/drawable-mdpi',
      'android/app/src/main/res/drawable-xhdpi',
      'android/app/src/main/res/drawable-xxhdpi',
      'android/app/src/main/res/drawable-xxxhdpi',
    ];
    
    final mipmapFolders = [
      'android/app/src/main/res/mipmap-hdpi',
      'android/app/src/main/res/mipmap-mdpi',
      'android/app/src/main/res/mipmap-xhdpi',
      'android/app/src/main/res/mipmap-xxhdpi',
      'android/app/src/main/res/mipmap-xxxhdpi',
    ];
    
    // Copy from mipmap to drawable folders
    for (int i = 0; i < drawableFolders.length; i++) {
      final drawableDir = Directory(drawableFolders[i]);
      if (!drawableDir.existsSync()) {
        drawableDir.createSync(recursive: true);
      }
      
      String sourceFolder;
      if (i == 0) {
        // For drawable folder, use mdpi as source
        sourceFolder = mipmapFolders[1];
      } else {
        sourceFolder = mipmapFolders[i - 1];
      }
      
      final sourceIcon = File('$sourceFolder/ic_launcher.png');
      
      // Copy only ic_launcher_foreground.png to drawable folders (they don't need ic_launcher.png)
      final targetForegroundIcon = File('${drawableFolders[i]}/ic_launcher_foreground.png');
      
      if (sourceIcon.existsSync()) {
        await sourceIcon.copy(targetForegroundIcon.path);
        print('   ✅ Copied to ${drawableFolders[i]} (ic_launcher_foreground.png)');
      }
    }
    
    print('');
    print('📱 Generated icons for:');
    print('   • Android (all densities) - static icons');
    print('   • Android drawable folders - updated');
    print('   • ic_launcher_foreground.png in drawable folders');
    print('   • iOS (all required sizes)');
    print('   • Your logo background is preserved');
    print('');
    print('🚀 Next steps:');
    print('   1. Run "flutter clean"');
    print('   2. Run "flutter pub get"');
    print('   3. Test your app to see the new icon');
    print('');
    print('📝 Note: Your logo will appear exactly as designed');
    print('   with its integrated background on all devices.');
  } else {
    print('❌ Failed to generate icons');
    print('Output: ${iconResult.stdout}');
    print('Error: ${iconResult.stderr}');
    exit(1);
  }
} 