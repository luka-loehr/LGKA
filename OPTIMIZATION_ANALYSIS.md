# LGKA App Optimization Analysis

## Current App Metrics

### Codebase Size
- **Dart Files**: 40 files
- **Total Lines**: ~13,273 lines
- **Assets**: 296KB (2 PNG images)
- **Debug APK Size**: 128MB (uncompressed, includes debug symbols)

### Estimated Release APK Size
- **Without optimization**: ~40-50MB
- **With current optimizations**: ~30-40MB
- **Target**: <25MB

---

## Biggest Dependencies (by size impact)

### 🔴 Heavy Dependencies (>5MB each)

1. **Syncfusion Flutter PDF** (`syncfusion_flutter_pdf: ^32.1.19`)
   - **Size Impact**: ~8-12MB
   - **Usage**: PDF text extraction for substitution plans
   - **Files Using**: 2 files (substitution_service.dart, pdf_viewer_screen.dart)
   - **Status**: ✅ Required (core feature)

2. **Syncfusion Flutter Charts** (`syncfusion_flutter_charts: ^32.1.19`)
   - **Size Impact**: ~6-10MB
   - **Usage**: Weather data visualization
   - **Files Using**: 1 file (weather_page.dart)
   - **Status**: ✅ Required (core feature)

3. **Flutter InAppWebView** (`flutter_inappwebview: ^6.1.5`)
   - **Size Impact**: ~5-8MB
   - **Usage**: Krankmeldung form, bug report form
   - **Files Using**: 2 files (webview_screen.dart, bug_report_screen.dart)
   - **Status**: ✅ Required (core feature)

### 🟡 Medium Dependencies (1-5MB each)

4. **PDFx** (`pdfx: ^2.9.1`)
   - **Size Impact**: ~3-5MB
   - **Usage**: PDF viewing/rendering
   - **Status**: ✅ Required (core feature)

5. **Photo View** (`photo_view: ^0.15.0`)
   - **Size Impact**: ~2-4MB
   - **Usage**: PDF zoom/pan functionality
   - **Status**: ✅ Required (core feature)

6. **Flutter Fireworks** (`flutter_fireworks: ^1.0.8`)
   - **Size Impact**: ~2-3MB (includes Flame game engine)
   - **Usage**: Celebration animations
   - **Status**: ⚠️ Optional (can be removed if not critical)

### 🟢 Light Dependencies (<1MB each)

- `go_router`, `flutter_riverpod`, `shared_preferences`, `http`, `csv`, `html`, `intl`, `timezone`, `share_plus`, `url_launcher`, `package_info_plus`

---

## Optimization Opportunities

### 🎯 High Impact Optimizations

#### 1. **Remove Flutter Fireworks** (Save ~2-3MB)
- **Impact**: Medium size reduction
- **Effort**: Low
- **Risk**: Low (optional feature)
- **Action**: Remove `flutter_fireworks` dependency and `FireworksOverlay` widget
- **Files to modify**: 
  - `lib/main.dart` (remove FireworksOverlay wrapper)
  - `lib/widgets/fireworks_overlay.dart` (delete)
  - `lib/providers/fireworks_provider.dart` (delete)
  - `pubspec.yaml` (remove dependency)

#### 2. **Asset Optimization** (Save ~100-150KB)
- **Current**: 2 PNG images (296KB total)
- **Action**: Convert PNGs to WebP format
- **Expected savings**: 30-50% reduction
- **Tools**: Use `flutter pub run flutter_launcher_icons` or manual conversion

#### 3. **Code Splitting / Lazy Loading**
- **Current**: All screens loaded at startup
- **Action**: Implement lazy loading for:
  - PDF viewer (only load when needed)
  - Weather charts (defer heavy chart library)
  - WebView screens (load on demand)
- **Impact**: Faster startup, smaller initial bundle

#### 4. **ProGuard/R8 Optimization** (Already Enabled ✅)
- **Status**: ✅ `isMinifyEnabled = true`, `isShrinkResources = true`
- **Impact**: Already saving ~20-30% on release builds

### 🎯 Medium Impact Optimizations

#### 5. **Remove Unused Dependencies**
- Check if all dependencies are actually used
- Consider alternatives for heavy dependencies

#### 6. **Image Asset Optimization**
- Convert PNG → WebP (better compression)
- Use vector graphics where possible
- Remove unused assets

#### 7. **Tree Shaking**
- Ensure unused code is removed
- Check for unused imports/exports
- Use `--split-debug-info` for release builds

### 🎯 Low Impact Optimizations

#### 8. **Reduce Syncfusion Bundle Size**
- **Note**: Syncfusion is commercial and large by design
- **Alternative**: Consider lighter chart libraries (fl_chart, charts_flutter)
- **Trade-off**: Less features, smaller size
- **Recommendation**: Keep Syncfusion (it's a core feature)

#### 9. **Optimize PDF Processing**
- Cache extracted text metadata
- Lazy load PDF parsing
- Use isolates for heavy PDF operations (already done ✅)

#### 10. **Build Configuration**
- Enable split APKs by ABI (arm64-v8a, armeabi-v7a)
- Use App Bundle instead of APK
- Enable `--split-per-abi` flag

---

## Recommended Actions (Priority Order)

### Immediate (High ROI)
1. ✅ **Remove Flutter Fireworks** - Easy win, saves 2-3MB
2. ✅ **Convert assets to WebP** - Quick, saves ~100KB
3. ✅ **Verify all dependencies are used** - Clean up unused packages

### Short-term (Medium ROI)
4. **Implement lazy loading** for heavy screens
5. **Optimize build configuration** (split APKs, App Bundle)
6. **Review Syncfusion usage** - ensure we're using minimal features

### Long-term (Lower ROI)
7. **Consider alternative chart library** (if Syncfusion becomes too heavy)
8. **Implement code splitting** at module level
9. **Profile and optimize** specific performance bottlenecks

---

## Performance Optimizations

### Already Implemented ✅
- ✅ 5-minute caching for all data sources
- ✅ Background refresh for expired caches
- ✅ PDF caching to avoid re-downloads
- ✅ Lazy loading for weather charts (progressive rendering)
- ✅ Isolate usage for PDF text extraction
- ✅ Minification and resource shrinking enabled

### Additional Opportunities
- **Debounce search inputs** (PDF viewer)
- **Virtual scrolling** for long lists (news screen)
- **Image caching** for webview content
- **Reduce rebuilds** with more granular state management

---

## Size Breakdown Estimate

### Current Release APK (~30-40MB)
- **Native libraries**: ~15-20MB
- **Dart code**: ~2-3MB
- **Assets**: ~0.3MB
- **Dependencies**:
  - Syncfusion PDF: ~8-12MB
  - Syncfusion Charts: ~6-10MB
  - InAppWebView: ~5-8MB
  - PDFx + Photo View: ~5-9MB
  - Others: ~2-3MB

### After Optimizations (~25-30MB)
- Remove Fireworks: -2-3MB
- Asset optimization: -0.1MB
- Better tree shaking: -1-2MB
- **Total savings**: ~3-5MB

---

## Next Steps

1. **Remove Flutter Fireworks** (if not critical feature)
2. **Convert assets to WebP**
3. **Build release APK** and measure actual size
4. **Profile app** to identify performance bottlenecks
5. **Consider App Bundle** instead of APK for Play Store
