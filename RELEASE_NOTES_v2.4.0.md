iOS: https://apps.apple.com/app/lgka/id6747010920  
Android: https://play.google.com/store/apps/details?id=com.lgka

## Highlights

This release introduces a comprehensive news feature, intelligent haptic feedback throughout the app, and major improvements to caching and error handling. The app now provides a more responsive and polished user experience with better performance and reliability.

## What's Changed

### News Feature
- Added full news screen with automatic loading on app launch
- Implemented news detail screen with full article content, images, and clickable links
- Added recommended articles section on detail screen
- Integrated news into drawer menu with "Neuigkeiten" option
- Added fade-in animations for news cards
- Improved news error handling with automatic retry logic
- Added support for download links with file type icons and sizes
- Added styled link buttons for news articles with favicons

### Haptic Feedback System
- Implemented intelligent haptic feedback system for loading states
- Added haptic feedback to all UI buttons and interactions
- Added medium haptic feedback on successful data loads (substitutions, schedules, news)
- Added light haptic feedback for navigation and menu interactions
- Added intense haptic feedback for errors and important actions
- Improved haptic feedback during PageView swiping between main screens
- Added haptic feedback to onboarding flow buttons
- Added New Year fireworks feature with haptic feedback

### Schedule & Timetables
- Enhanced error handling with automatic retry logic (up to 2 retries)
- Reduced cache validity from 5 minutes to 2 minutes for fresher live data

### Substitution Plans
- Extracted substitution functionality into dedicated service
- Migrated to substitutionProvider for better state management
- Improved error handling and retry logic
- Added haptic feedback on successful substitution plan loads
- Enhanced debug logging for troubleshooting

### Weather Screen
- Improved error handling with timezone-based data collection window
- Added automatic retry logic (up to 2 retries)
- Enhanced weather chart availability checks
- Improved chart rendering and x-axis interval calculation

### UI & Design
- Redesigned auth screen to match accent color screen layout
- Added accent color picker with fade animation
- Improved news detail screen design with accent colors
- Enhanced drawer menu styling with icon backgrounds and better spacing
- Added slide animations for news detail screen navigation
- Improved spacing and visual balance across screens
- Added website favicons to standalone link buttons

### PDF Viewer
- Improved PDF loading and error handling
- Added retry logic using RetryUtil for consistent behavior

### Onboarding
- Added comprehensive onboarding flow with welcome, info, accent color, and auth screens
- Improved onboarding completion flow
- Added haptic feedback throughout onboarding
- Enhanced visual design and animations

### Other Features
- Added support project link to settings
- Improved error messages and user feedback
- Enhanced loading states and spinner tracking
- Fixed localization for legal screen and schedule option labels

### Under the Hood
- Created centralized CacheService for managing all cache validity across services
- Extracted HapticService from providers to services folder
- Organized screens directory into categorized subdirectories (content, info, onboarding, settings, viewers)
- Added RetryUtil for automatic retry logic on network errors
- Updated major dependencies: syncfusion_flutter_charts 32.1.19, syncfusion_flutter_pdf 32.1.19
- Converted assets to WebP format for better compression
- Removed unused dependencies and cleaned up codebase
- Improved logging system to professional format without emojis
- Added comprehensive localization support for new features

## Version Info
- Version: 2.4.0 (Build 282)
- Platforms: iOS 13.0+, Android 7.0+

---

## Legal
Developer: Luka Löhr  
Imprint: https://luka-loehr.github.io/LGKA/impressum.html  
Privacy: https://luka-loehr.github.io/LGKA/privacy.html

This is an unofficial helper app for students of Lessing-Gymnasium Karlsruhe and is not directly affiliated with the school administration.
