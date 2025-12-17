# Release Workflow

## Trigger Phrases

Initiate when user says: "prepare release", "release", "create release", "new release", or similar.

## Pre-Workflow

**CRITICAL**: Before starting, create a task list with all tasks below using the todo_write tool. Mark tasks as you complete them.

## Tasks

### Task 1: Version Bump and Tag

1. Note the current latest tag (this is `[previous_tag]` for later)
2. Read current version from `pubspec.yaml`
3. Increment: version +0.0.1, build number +1
4. Update `pubspec.yaml`, commit, tag with new version, push commit and tag

### Task 2: Gather Changes

Get all changes between `[previous_tag]` and HEAD:
- `git log --pretty=format:"%h - %s" [previous_tag]..HEAD`
- `git diff --stat [previous_tag]..HEAD`

### Task 3: Create GitHub Release

1. Create release notes following the template at `agents/templates/release_notes_template.md`
2. Create GitHub release via CLI:
   - Title format: `LGKA+ vx.x.x`
   - Attach release notes

### Task 4: Build and Upload ARM64 APK

1. Build: `flutter build apk --release --target-platform android-arm64`
2. Upload APK to the GitHub release via `gh release upload`
   - **Important**: The APK must be named exactly `app-release.apk` when uploaded

### Task 5: Build Google Play App Bundle

Build: `flutter build appbundle --release`

### Task 6: Create Xcode Archive

Build: `flutter build ipa --release`

### Task 7: Copy Archive to Xcode Organizer

Copy the archive to `~/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/` so it appears in Xcode Organizer.

### Task 8: App Store Release Notes

1. Create German-language release notes following `agents/templates/appstore_release_template.md`
2. **Output the App Store release notes directly in chat** (not just as a file)

## File Locations

- Release notes template: `agents/templates/release_notes_template.md`
- App Store template: `agents/templates/appstore_release_template.md`
- Version: `pubspec.yaml`
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- Xcode archives: `~/Library/Developer/Xcode/Archives/`
