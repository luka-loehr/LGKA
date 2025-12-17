# LGKA Flutter App - Build Notes

## License Notice

**ATTENTION**: This app is licensed under **Creative Commons BY-NC-ND 4.0 License**.

**Not Allowed:**
- Creating and publishing your own app versions
- Uploading to App Stores by third parties
- Commercial use
- Distribution of modified versions

**Allowed:**
- Studying and understanding the code
- Local development builds for learning
- Contributing via Pull Requests

**Only the original developer (Luka Löhr) may create official releases.**

---

## Build Configuration

### Optimizations
- **R8 Full Mode**: Enabled in `gradle.properties`
- **Resource Shrinking**: Removes unused resources
- **ProGuard**: Dead-code elimination
- **Icon Tree-Shaking**: 99%+ font reduction

## Production Builds

### Google Play Store
```bash
flutter build appbundle --release
```
- **Output**: `build/app/outputs/bundle/release/app-release.aab`
- **Size**: ~45MB (Play Store optimized to ~9MB)

### Apple App Store
```bash
flutter build ios --release
```

## Development Builds

### Split APKs for Testing
```bash
flutter build apk --release --split-per-abi
```

**Output Files:**
- `app-arm64-v8a-release.apk` (~9.9MB)
- `app-armeabi-v7a-release.apk` (~9.5MB)
- `app-x86_64-release.apk` (~10.0MB)

### Installation
```bash
# Check device ABI
adb shell getprop ro.product.cpu.abi

# Install APK
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## Build Sizes

| Build Type | Size | Usage |
|-----------|-------|------------|
| App Bundle | ~45MB | Google Play Store |
| ARM64 APK | ~9.9MB | Development/Testing |
| ARMv7 APK | ~9.5MB | Development/Testing |
| x86_64 APK | ~10.0MB | Emulator/Testing |

## Troubleshooting

### APK Installation Failed
```bash
# Remove old version
adb uninstall com.lgka

# Install new version
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Build Size Too Large
- **Problem**: Universal APK instead of Split APK
- **Solution**: Use `--split-per-abi` flag
- **Don't use**: `flutter build apk --release` (creates Universal APK ~30MB)

---

**Only official releases by Luka Löhr. Developers can create local builds for learning purposes.**
