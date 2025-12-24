# Architecture Analysis & Refactoring Plan

## Current Structure Issues

### 1. **PDF Repository Usage** ❌
**Problem**: PDF Repository is still being used directly instead of SubstitutionProvider
- `home_screen.dart` uses `pdfRepositoryProvider` directly
- `main.dart` uses `pdfRepositoryProvider` for preloading
- `retry_service.dart` uses `pdfRepositoryProvider`
- **Solution**: Should use `substitutionProvider` instead (which we already created!)

### 2. **Screen Structure** ❌
**Problem**: `home_screen.dart` is a 1482-line monolith containing:
- `HomeScreen` - Main container with tab navigation
- `_SubstitutionPlanPage` - Should be its own `substitution_screen.dart` file
- `_StundenplanPage` - Appears to be unused/dead code
- Multiple button widgets (`_PlanOptionButton`, `_ScheduleOptionButton`, etc.)
- Settings and drawer sheets

**Comparison**:
- ✅ `schedule_page.dart` - 640 lines, separate file
- ✅ `weather_page.dart` - 1159 lines, separate file  
- ❌ `_SubstitutionPlanPage` - Embedded in home_screen.dart (should be separate!)

### 3. **Services & Providers** ✅
**Good**: All services have their own providers:
- ✅ `news_service.dart` + `news_provider.dart`
- ✅ `schedule_service.dart` + `schedule_provider.dart`
- ✅ `substitution_service.dart` + `substitution_provider.dart` (created but NOT used!)
- ✅ `weather_service.dart` + `weatherDataProvider` (in app_providers.dart)

### 4. **Data Folder** ⚠️
**Question**: Why is `pdf_repository.dart` in `data/` folder?
- It's now just a wrapper around `SubstitutionService`
- Should either be removed or moved to `services/` if we keep it for backward compatibility

## Refactoring Plan

### Phase 1: Extract Substitution Screen
1. Create `lib/screens/content/substitution_screen.dart`
2. Move `_SubstitutionPlanPage` and related widgets to new file
3. Update `home_screen.dart` to import and use the new screen
4. Remove unused `_StundenplanPage` code

### Phase 2: Migrate from PDF Repository to Substitution Provider
1. Update `home_screen.dart` to use `substitutionProvider` instead of `pdfRepositoryProvider`
2. Update `main.dart` to use `substitutionProvider` for preloading
3. Update `retry_service.dart` to use `substitutionProvider`
4. Consider deprecating `pdfRepositoryProvider` (or keep as thin wrapper)

### Phase 3: Clean Up Home Screen
1. Extract button widgets to separate files if reusable
2. Extract settings/drawer sheets to separate files
3. Keep `HomeScreen` focused only on tab navigation

## File Size Comparison
- `home_screen.dart`: **1482 lines** (too large!)
- `schedule_page.dart`: 640 lines
- `weather_page.dart`: 1159 lines
- Target: `substitution_screen.dart` should be ~400-600 lines
