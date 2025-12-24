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

**CRITICAL**: To find what's actually new, compare the previous release tag with the current release tag, NOT just what's in the release notes file.

1. First, identify the previous release tag:
   - List available tags: `git tag --list | grep -E "^v?2\.[0-9]+\.[0-9]+" | sort -V`
   - Fetch tags if needed: `git fetch --tags`
   - The previous tag is typically the one before the current version (e.g., if releasing 2.4.0, previous is 2.3.0)

2. Compare the two release tags to get actual changes:
   - Get commit log: `git log --pretty=format:"%h - %s" [previous_tag]..[current_tag]`
   - Get file statistics: `git diff --stat [previous_tag]..[current_tag]`
   - **Note**: Tag formats may differ (e.g., `2.3.0` vs `v2.4.0`), so use the exact tag names from `git tag --list`

3. Analyze the commits to identify:
   - New features introduced
   - User-visible changes
   - Bug fixes
   - Performance improvements
   - UI/UX improvements

### Task 3: Create GitHub Release

1. Create release notes following the template at `agents/templates/release_notes_template.md`
   - **CRITICAL**: When creating release notes files (e.g., `RELEASE_NOTES_v2.4.0.md`), DO NOT include the template header "# GitHub Release Notes Template" or any other template metadata. The release notes file should start directly with the actual content (e.g., iOS/Android links, Highlights section, etc.). Template headers are for reference only and must be removed before using the file.
2. Create GitHub release via CLI:
   - Title format: `LGKA+ vx.x.x`
   - Attach release notes
   - **IMPORTANT**: Verify the release notes file does NOT contain template headers before uploading. The file should start with actual content, not template instructions.

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

1. **CRITICAL**: To determine what's actually new in this release, compare the previous release with the current release:
   - Identify previous release tag: `git tag --list | grep -E "^v?2\.[0-9]+\.[0-9]+" | sort -V`
   - Fetch tags if needed: `git fetch --tags`
   - Compare releases: `git log --pretty=format:"%h - %s" [previous_tag]..[current_tag]`
   - **DO NOT** rely solely on the RELEASE_NOTES file - it may contain cumulative information. Always compare actual git commits between the two release tags to identify what's newly introduced in this specific release.

2. Get the actual GitHub release URL using the CLI:
   - Run: `gh release view [version_tag] --json tagName --jq .tagName` to get the tag name
   - Construct the release URL as: `github.com/luka-loehr/LGKA/releases/tag/[tagName]`
   - **DO NOT** make up or guess the release URL - always get it from the CLI using the actual tag name
   - Example: If tag is `v2.4.0`, URL is `github.com/luka-loehr/LGKA/releases/tag/v2.4.0`

3. Create German-language release notes following `agents/templates/appstore_release_template.md`
   - Use the examples in the template as guidance for quality and style
   - Focus ONLY on user-visible changes that are NEW in this release compared to the previous release
   - Base content on the git commit comparison, not on the full release notes file
   - Keep it concise and student-friendly
   - Highlight what students will actually notice and experience

4. **Output the App Store release notes directly in chat** (not just as a file)

## File Locations

- Release notes template: `agents/templates/release_notes_template.md`
- App Store template: `agents/templates/appstore_release_template.md`
- Version: `pubspec.yaml`
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- Xcode archives: `~/Library/Developer/Xcode/Archives/`
