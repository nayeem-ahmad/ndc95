# Profile Picture Upload Feature

## Overview
Users can now change their profile picture by uploading from camera or gallery with cropping functionality.

## Features Implemented

### 1. Profile Picture Management
- **Default Photo**: Initially uses Google profile picture from authentication
- **Custom Upload**: Users can upload their own profile picture
- **Storage**: Images stored in Firebase Storage at `profile_pictures/{userId}.jpg`
- **Persistence**: Photo URL saved to both Firestore and Firebase Auth profile

### 2. Image Sources
Users can choose from two sources:
- **📷 Camera**: Take a new photo using device camera
- **🖼️ Gallery**: Select an existing photo from device gallery

### 3. Image Cropping
- **Square Crop**: Enforces square aspect ratio (1:1) for profile pictures
- **Resizable**: Users can zoom and pan to select the desired portion
- **Interactive UI**: 
  - Android: Material design cropper with blue toolbar
  - iOS: Native iOS cropper interface

### 4. User Interface

#### Profile Screen UI Changes:
- **Profile Picture Display**:
  - Circular avatar (80px diameter)
  - Network image loading from Firebase Storage or Google
  - Placeholder icon if no image available
  
- **Change Picture Button**:
  - Camera icon badge on bottom-right of profile picture
  - Blue circular button with white border
  - Tap to open image source selection

- **Loading State**:
  - Shows circular progress indicator while uploading
  - Prevents multiple simultaneous uploads

#### Modal Bottom Sheet:
- Clean, modern design with rounded top corners
- Handle indicator at top
- Title: "Change Profile Picture"
- Two options with icons:
  - Take Photo (camera icon)
  - Choose from Gallery (photo library icon)

### 5. Success & Error Handling
- **Success**: Green SnackBar with confirmation message
- **Error**: Red SnackBar with error details
- **User Cancellation**: Graceful handling if user cancels at any step

## Technical Implementation

### Dependencies Added:
```yaml
image_picker: ^1.0.4      # Pick images from camera/gallery
image_cropper: ^5.0.1     # Crop images with UI
```

### Android Permissions (AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

### Firebase Storage Structure:
```
storage/
└── profile_pictures/
    └── {userId}.jpg    # One image per user, overwrites on update
```

### Firestore Data Structure:
```dart
users/{userId}/
  photoUrl: "https://firebasestorage.googleapis.com/..."  // Custom or Google URL
  updatedAt: Timestamp
```

## Code Flow

### 1. Upload Process:
```
User taps camera button
  ↓
Modal bottom sheet appears
  ↓
User selects Camera or Gallery
  ↓
Image picker opens
  ↓
User selects/captures image
  ↓
Image cropper opens
  ↓
User crops to square
  ↓
Image uploads to Firebase Storage
  ↓
Download URL received
  ↓
Firestore profile updated
  ↓
Firebase Auth profile updated
  ↓
UI refreshes with new image
  ↓
Success message shown
```

### 2. Key Methods:

#### `_pickAndCropImage(ImageSource source)`
- Picks image from camera or gallery
- Opens cropper with square aspect ratio locked
- Uploads cropped image to Firebase Storage
- Updates profile URLs in Firestore and Auth
- Handles all errors gracefully

#### `_showImageSourceDialog()`
- Shows modal bottom sheet
- Presents camera/gallery options
- Dismisses and triggers image picker

#### `FirebaseService.uploadProfilePicture()`
- Uploads file to Firebase Storage
- Generates public download URL
- Updates user profile in Firestore
- Updates Firebase Auth photoURL

## User Experience

### Flow Example:
1. User navigates to **My Profile** tab
2. Sees current profile picture (Google or custom)
3. Taps **camera icon badge** on profile picture
4. **Bottom sheet** slides up with options
5. User selects **"Take Photo"** or **"Choose from Gallery"**
6. Camera opens or gallery shows
7. User captures/selects image
8. **Cropper screen** appears
9. User adjusts crop area (square)
10. User confirms crop
11. **Loading indicator** appears
12. Image uploads to cloud
13. Profile picture updates instantly
14. **Success message** appears: "Profile picture updated successfully!"

## Benefits

### For Users:
- ✅ Easy to change profile picture
- ✅ Professional square cropping
- ✅ Choice of camera or gallery
- ✅ Instant preview after upload
- ✅ No need to leave the app

### For Developers:
- ✅ Firebase Storage integration
- ✅ Automatic URL management
- ✅ Profile sync across Firestore and Auth
- ✅ Overwrite instead of accumulate (saves storage)
- ✅ Proper error handling

## Image Quality
- **Compression**: Images compressed to 80% quality during picking
- **Format**: Stored as JPEG (.jpg)
- **Storage Location**: Firebase Storage with auto-generated download URLs
- **Access**: Public read access via download URL

## Security Notes
- Images stored with user ID as filename (e.g., `userId.jpg`)
- Only authenticated users can upload
- Firebase Storage rules should be configured to:
  - Allow authenticated users to write to their own profile picture
  - Allow public read access to all profile pictures

## Storage Rules (Recommended):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_pictures/{userId} {
      // Anyone can read profile pictures
      allow read: if true;
      
      // Only authenticated users can upload their own picture
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Future Enhancements
- [ ] Remove/delete profile picture option
- [ ] Multiple aspect ratios (circle, square, wide)
- [ ] Filters and effects
- [ ] Image size validation (max 5MB)
- [ ] Compress before upload for faster loading
- [ ] Progress indicator during upload
- [ ] Offline support with local caching
- [ ] Profile picture history/gallery

## Testing Checklist
- [x] Camera permission request
- [x] Gallery permission request
- [x] Camera capture works
- [x] Gallery selection works
- [x] Cropper opens and works
- [x] Square aspect ratio maintained
- [x] Upload to Firebase Storage
- [x] Firestore profile update
- [x] Auth profile update
- [x] UI refreshes with new image
- [x] Success message displays
- [x] Error handling works
- [x] Loading state shows during upload
- [x] User can cancel at any step

## Known Limitations
- Single image only (overwrites previous)
- Camera permission required for camera option
- Storage permission required for gallery option (Android 12 and below)
- Requires active internet connection to upload
- No offline queue for uploads

## Troubleshooting

### Camera Not Opening:
- Check camera permission in AndroidManifest.xml
- Ensure device has camera hardware
- Request runtime permission on Android 6+

### Gallery Not Opening:
- Check storage/media permissions
- For Android 13+, uses READ_MEDIA_IMAGES
- For Android 12-, uses READ_EXTERNAL_STORAGE

### Upload Fails:
- Check internet connection
- Verify Firebase Storage is enabled
- Check Firebase Storage rules
- Ensure user is authenticated
- Check file size (some devices have limits)

### Image Not Showing:
- Check Firestore update succeeded
- Verify download URL is valid
- Check network image caching
- Ensure NetworkImage has internet permission

---
**Feature Status**: ✅ Fully Implemented and Tested
**Last Updated**: October 1, 2025
**Version**: 1.1.0
