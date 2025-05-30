# App Icons

This folder contains your app logo file for generating platform-specific app icons.

## Required File:
Place your app logo here as:
- `app-logo.png` - Your complete app logo with background (1024x1024px recommended)

## Logo Specifications:
- **Format**: PNG (can have solid background or transparent)
- **Size**: 1024x1024px minimum for best quality
- **Background**: Your logo should include its own background (no adaptive icons)
- **Design**: Should look good at small sizes (as small as 16x16px)
- **Safe area**: Keep important elements within the center 80% of the image

## How to Generate App Icons:
1. Place your `app-logo.png` (1024x1024px) in this folder
2. Run: `dart run generate_app_icons.dart`
3. Or manually run: `dart run flutter_launcher_icons:main`

This will generate all required icon sizes for both Android and iOS using your static logo.

## What Gets Generated:
- **Android**: All density variants (hdpi, xhdpi, xxhdpi, xxxhdpi) as static icons
- **iOS**: All required icon sizes (20x20 to 1024x1024)
- Your logo will be used as-is, maintaining the background you've designed

## Recommended Tools for Logo Creation:
- [Canva](https://canva.com) - Easy logo design with backgrounds
- [GIMP](https://gimp.org) - Free image editor
- [Figma](https://figma.com) - Professional design tool 