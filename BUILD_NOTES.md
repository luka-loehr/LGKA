# LGKA Flutter App - Build Notes & Debug Symbols Guide

## Overview
This document explains the improvements made to resolve the Google Play Console warning about missing debug symbols and general app optimization.

## Issue Fixed
**Google Play Console Warning**: "This App Bundle contains native code, and you've not uploaded debug symbols. We recommend you upload a symbol file to make your crashes and ANRs easier to analyze and debug."

## Improvements Made

### 1. Enhanced Android Build Configuration
- **File**: `android/app/build.gradle.kts`
- **Changes**:
  - Added proper NDK configuration with `debugSymbolLevel = "FULL"`
  - Improved packaging options to keep debug symbols: `keepDebugSymbols += "**/*.so"`
  - Enabled ProGuard optimization with proper rule configurations
  - Enhanced signing configuration for release builds

### 2. Optimized ProGuard Rules
- **File**: `android/app/proguard-rules.pro`
- **Added comprehensive rules for**:
  - Flutter framework classes
  - Google Play Core libraries (resolves R8 compilation issues)
  - Plugin-specific classes (permission_handler, path_provider, syncfusion_pdf, etc.)
  - Native method preservation for crash reporting
  - Deferred component support

### 3. Updated Gradle Properties
- **File**: `android/gradle.properties`
- **Optimizations**:
  - Increased JVM memory allocation for better build performance
  - Enabled parallel builds and caching
  - Configured R8 for optimal code optimization
  - Removed deprecated properties that were causing build failures

## Debug Symbol Files Generated

### Flutter Debug Symbols
Located in `symbols/` directory:
- `app.android-arm.symbols` - ARMv7 architecture symbols
- `app.android-arm64.symbols` - ARM64 architecture symbols  
- `app.android-x64.symbols` - x86_64 architecture symbols
- `debug-symbols.zip` - Compressed Flutter symbols for upload

### Native Library Symbols
Located in `native-symbols.zip`:
- `arm64-v8a/` - Contains libapp.so, libflutter.so, libdatastore_shared_counter.so
- `armeabi-v7a/` - Contains native libraries for ARMv7
- `x86_64/` - Contains native libraries for x86_64

## Build Commands Used

### Standard Release Build
```bash
flutter build appbundle --release --build-name=1.3.0 --build-number=12
```

### Build with Debug Symbols (Recommended)
```bash
flutter build appbundle --release --build-name=1.3.0 --build-number=12 --split-debug-info=symbols --obfuscate
```

This command:
- Creates a release build optimized for production
- Generates separate debug symbol files
- Obfuscates the Dart code for better security
- Preserves crash analysis capabilities

## Google Play Console Upload Guide

### 1. Upload the App Bundle
- Use: `build/app/outputs/bundle/release/app-release.aab`

### 2. Upload Debug Symbols
There are two symbol files you can upload:

#### Option A: Flutter Debug Symbols (Recommended)
- File: `symbols/debug-symbols.zip`
- Contains: Dart/Flutter-specific symbols for crash analysis
- Best for: Flutter-specific crashes and ANR analysis

#### Option B: Native Library Symbols
- File: `native-symbols.zip`  
- Contains: Native library symbols (.so files)
- Best for: Native library crashes and low-level debugging

### 3. Upload Process in Google Play Console
1. Go to Play Console → Your App → Release → App Bundle Explorer
2. Select your release
3. Click "Download" tab
4. Under "Debug symbols", click "Upload debug symbols"
5. Upload the appropriate .zip file based on your needs

## App Size Optimization Achieved

### Before Optimization
- Basic release build without proper symbol handling
- Potential crashes harder to debug
- R8 compilation issues

### After Optimization  
- **App Bundle Size**: ~129MB (optimized)
- **Debug Symbol Files**: ~7.8MB (separate)
- **Native Libraries**: Properly organized by architecture
- **Code Obfuscation**: Enabled for better security
- **Crash Analysis**: Fully supported with symbol files

## Dependencies with Native Code
The following plugins in this app contain native code and benefit from proper symbol handling:
- `permission_handler` - Android permissions
- `path_provider` - File system access
- `syncfusion_flutter_pdf` - PDF processing
- `open_filex` - File opening functionality
- `package_info_plus` - App information

## Future Builds
To create optimized builds with debug symbols:

```bash
# Clean previous builds
flutter clean

# Get dependencies  
flutter pub get

# Build with symbols
flutter build appbundle --release --build-name=X.Y.Z --build-number=N --split-debug-info=symbols --obfuscate
```

Replace X.Y.Z with your version and N with your build number.

## Troubleshooting

### If you see "failed to strip debug symbols"
This is expected and actually desired - it means the symbols are preserved for crash analysis.

### If R8 compilation fails
Ensure the ProGuard rules in `proguard-rules.pro` include all necessary keep rules for your plugins.

### If deprecated Gradle properties error occurs
Check `gradle.properties` and remove any properties marked as deprecated in the Android Gradle Plugin version you're using.

---

## Summary
The app is now properly configured to:
✅ Generate comprehensive debug symbols for crash analysis  
✅ Build optimized release bundles with obfuscation
✅ Support all native plugin functionalities
✅ Provide better crash reporting on Google Play Console
✅ Maintain security through code obfuscation
✅ Optimize build performance with parallel processing 