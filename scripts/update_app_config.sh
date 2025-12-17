#!/bin/bash

# LGKA+ App Configuration Update Script
# This script applies centralized configuration to both Android and iOS

echo "LGKA+ App Configuration Update"
echo "=============================="
echo ""

# Check if configuration file exists
if [ ! -f "app_config/app_config.yaml" ]; then
    echo "[ERROR] app_config/app_config.yaml not found"
    echo "Please create the configuration file first."
    exit 1
fi

echo "Current configuration:"
echo "$(cat app_config/app_config.yaml | grep -E '(app_name|version_name|version_code|app_icon_path):')"
echo ""

# Get dependencies first
echo "[INFO] Getting dependencies..."
flutter pub get

# Apply configuration
echo "[INFO] Applying configuration..."
dart run scripts/apply_app_config.dart

# Generate app icons
echo "[INFO] Generating app icons..."
dart run flutter_launcher_icons

echo ""
echo "[OK] Configuration update complete!"
echo ""
echo "Next steps:"
echo "1. Clean and rebuild your app:"
echo "   flutter clean && flutter build ios --debug --simulator"
echo "   flutter clean && flutter build apk --debug"
echo ""
echo "2. Test on both platforms to verify changes"
echo ""
echo "To make changes:"
echo "   Edit app_config/app_config.yaml and run this script again"
