#!/bin/bash

# App Icon Generation Script for NDC95

echo "🎨 NDC95 App Icon Setup"
echo "======================="
echo ""

# Check if the icon image exists
if [ ! -f "assets/images/app_icon.png" ]; then
    echo "❌ Error: Icon image not found!"
    echo ""
    echo "Please save the Notredamians '95 tree logo as:"
    echo "  assets/images/app_icon.png"
    echo ""
    echo "The image should be:"
    echo "  - PNG format"
    echo "  - At least 1024x1024 pixels"
    echo "  - The circular blue logo with colorful hands tree"
    echo ""
    exit 1
fi

echo "✅ Found app_icon.png"
echo ""

# Check image dimensions
if command -v sips &> /dev/null; then
    echo "📏 Checking image dimensions..."
    sips -g pixelWidth -g pixelHeight assets/images/app_icon.png
    echo ""
fi

# Generate icons
echo "🚀 Generating app icons for Android and iOS..."
echo ""
flutter pub run flutter_launcher_icons

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ App icons generated successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Run: flutter clean"
    echo "  2. Run: flutter build apk (or flutter run)"
    echo "  3. Check your app on device/emulator"
    echo ""
    echo "The new icon should appear on your home screen! 🎉"
else
    echo ""
    echo "❌ Error generating icons. Please check the logs above."
    exit 1
fi
