# App Icon Setup Guide

This guide explains how to set up the NDC95 app icon with the Notredamians '95 tree logo.

## Current Status

The app is configured to use the custom app icon. The configuration is ready in `pubspec.yaml`.

## Steps to Complete Setup

### 1. Save the App Icon Image

Save the Notredamians '95 tree logo (the circular blue image with colorful hands forming a tree) as:
```
/Users/bs01621/ndc95/assets/images/app_icon.png
```

**Image Requirements:**
- Format: PNG
- Recommended size: 1024x1024 pixels or larger
- The image should be the full circular logo with the blue background
- This will be automatically resized for all platforms

### 2. Install Dependencies

Run the following command to install the icon generation package:
```bash
cd /Users/bs01621/ndc95
flutter pub get
```

### 3. Generate App Icons

Run this command to automatically generate all required icon sizes:
```bash
flutter pub run flutter_launcher_icons
```

This will create:
- **Android icons**: Multiple sizes in `android/app/src/main/res/mipmap-*/`
- **iOS icons**: Multiple sizes in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Adaptive icons**: For Android 8.0+ with the blue background color

### 4. Verify the Icons

After generation, check:
- Android: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### 5. Rebuild the App

```bash
flutter clean
flutter build apk
# or
flutter run
```

## Configuration Details

The app icon configuration in `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
  adaptive_icon_background: "#2E3E84"  # Dark blue from the logo
  adaptive_icon_foreground: "assets/images/app_icon.png"
  remove_alpha_ios: true
```

### Adaptive Icon (Android 8.0+)

- **Background color**: `#2E3E84` (the dark blue from the logo)
- **Foreground**: The full logo image
- This creates a nice adaptive icon that looks good in various shapes (circle, square, squircle)

### iOS Icon

- Automatically removes alpha channel (required by Apple)
- Generates all required sizes for iPhone and iPad
- Creates 2x and 3x resolution versions

## Color Reference

The logo uses these colors:
- **Background**: Dark blue (#2E3E84)
- **Tree/Hands**: Multiple vibrant colors (green, yellow, orange, red, blue, pink, etc.)
- **Text**: "NOTREDAMIANS '95" in yellow/gold

## Troubleshooting

### Issue: Icons not updating after generation

**Solution**: 
```bash
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons
flutter run
```

### Issue: iOS icon has transparency issues

**Solution**: The `remove_alpha_ios: true` setting handles this automatically.

### Issue: Android adaptive icon background is wrong

**Solution**: Adjust the `adaptive_icon_background` color in `pubspec.yaml` if needed.

## Platform-Specific Notes

### Android
- The adaptive icon will show the logo on the blue background
- On Android 8.0+, the system may apply different shapes (circle, square, rounded square)
- The logo should be centered and not too close to edges

### iOS
- The icon must not have transparency (handled automatically)
- All corners will be rounded by iOS
- The icon appears in various sizes across iPhone and iPad

## Next Steps

1. Save the logo image as `app_icon.png` in the `assets/images/` folder
2. Run `flutter pub get`
3. Run `flutter pub run flutter_launcher_icons`
4. Test on both Android and iOS devices/emulators

## Support

If you encounter any issues:
- Check that the image path is correct
- Verify the image is at least 1024x1024 pixels
- Ensure the image is a valid PNG file
- Try `flutter clean` before regenerating icons
