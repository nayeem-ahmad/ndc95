# NDC95 App Features

## Overview
NDC95 is a Flutter-based community directory app with Google Sign-In authentication and Firebase backend.

## Current Features

### 1. Authentication
- ✅ Google Sign-In (OAuth 2.0)
- ✅ Persistent login with Firebase Authentication
- ✅ Auto-redirect to home screen for logged-in users
- ✅ Sign-out functionality

### 2. Bottom Navigation
The app now features a bottom navigation bar with two main tabs:

#### **Directory Tab** (Default View)
- Displays all registered users in the community
- Real-time updates using Firestore snapshots
- User cards showing:
  - Profile picture (or initial avatar if no photo)
  - Full name
  - Email address
  - Mobile phone number (or "No Phone" if not available)
  - "You" badge for the current user
- **Search functionality**:
  - Search by name, email, or phone number
  - Real-time filtering as you type
  - Clear button to reset search
- Empty states for:
  - No users found
  - No search results
  - Firestore API not enabled (with helpful error message)

#### **My Profile Tab**
- Personal profile view with:
  - Large profile picture
  - Welcome message with user's name
  - Email address
  - Celebration welcome card
  - Detailed user information card showing:
    - Full name
    - Email address
    - User ID (truncated)

### 3. UI/UX Features
- Modern Material Design 3
- Gradient backgrounds (blue to white)
- Rounded corners on cards
- Elevation effects for depth
- Smooth navigation transitions
- Responsive layout
- Scrollable content to prevent overflow

### 4. Firebase Integration
- **Firebase Authentication**: Google Sign-In provider
- **Cloud Firestore**: User profile storage
- **Real-time Database**: Instant updates when users join
- **Firebase Storage**: Ready for profile picture uploads
- **Firebase Messaging**: Prepared for push notifications

## User Profile Data Structure

Each user document in Firestore (`users` collection) contains:
```dart
{
  'email': 'user@example.com',
  'displayName': 'John Doe',
  'phoneNumber': '+1234567890',  // Optional
  'photoUrl': 'https://...',     // From Google account
  'createdAt': Timestamp,
  'updatedAt': Timestamp,
}
```

## Technical Stack

### Frontend
- **Flutter**: 3.9+
- **Dart**: 3.9.2
- **Material Design**: 3

### Backend (Firebase)
- **firebase_core**: 4.1.1
- **firebase_auth**: 6.1.0
- **cloud_firestore**: 6.0.2
- **firebase_storage**: 13.0.2
- **firebase_messaging**: 16.0.2
- **google_sign_in**: 6.3.0

### Platform
- **Package Name**: com.nayeemahmad.ndc95
- **Android**: minSdk 21, compileSdk 34
- **iOS**: Ready (configured)

## File Structure

```
lib/
├── main.dart                    # App entry point, login screen
├── firebase_options.dart        # Firebase configuration
├── screens/
│   ├── home_screen.dart        # Main screen with bottom navigation
│   ├── directory_screen.dart   # User directory with search
│   └── profile_screen.dart     # Personal profile view
└── services/
    └── firebase_service.dart   # Firebase service layer
```

## Setup Requirements

### Prerequisites
1. ✅ Firebase project created (`ndc95-9af5f`)
2. ✅ Google Sign-In enabled in Firebase Console
3. ✅ SHA-1 certificate registered
4. ⚠️ **Firestore API must be enabled** (see FIRESTORE_SETUP.md)

### First-time Setup
1. Clone the repository
2. Run `flutter pub get`
3. Enable Firestore API in Firebase Console
4. Run the app: `flutter run`

## Known Issues & Solutions

### 1. Firestore Permission Denied
**Issue**: Directory shows error "Cloud Firestore API has not been used..."

**Solution**: 
- Visit: https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=ndc95-9af5f
- Click "Enable"
- Wait 1-2 minutes
- Restart the app

### 2. Empty Directory
**Issue**: Directory shows "No users found"

**Cause**: Firestore API not enabled or no users have signed in yet

**Solution**:
- Enable Firestore API (see above)
- Sign in with Google - your profile will be created automatically
- Other users will appear as they sign in

### 3. Google Play Services Warnings (Emulator)
**Issue**: Console shows `SecurityException: Unknown calling package name`

**Note**: These are harmless warnings common on Android emulators. Google Sign-In works despite these warnings.

## Future Features (Planned)

### Phase 1: Enhanced Profiles
- [ ] Edit profile functionality
- [ ] Add/edit phone number
- [ ] Custom profile picture upload
- [ ] Bio/description field
- [ ] Location information
- [ ] Batch year or graduation info

### Phase 2: Photo Albums
- [ ] Create albums
- [ ] Upload photos/videos
- [ ] Share albums with community
- [ ] Like and comment on media
- [ ] Album privacy settings

### Phase 3: Social Features
- [ ] Create posts
- [ ] Like and comment on posts
- [ ] News feed
- [ ] Notifications for interactions
- [ ] Direct messaging

### Phase 4: Community Features
- [ ] Events calendar
- [ ] RSVP to events
- [ ] Group discussions
- [ ] Announcements
- [ ] Member directory filters (batch, location, etc.)

## Development Commands

```bash
# Run on Android emulator
flutter run -d emulator-5554

# Hot reload (while app is running)
r

# Hot restart
R

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build APK
flutter build apk

# Check for outdated packages
flutter pub outdated
```

## Git Repository
- **URL**: https://github.com/nayeem-ahmad/ndc95
- **Branch**: main
- **Latest Commit**: Bottom navigation with Directory and My Profile tabs

## Documentation Files
- `README.md`: Project overview
- `FIREBASE_SETUP.md`: Firebase configuration guide
- `FIRESTORE_SETUP.md`: Firestore enablement instructions
- `GOOGLE_SIGNIN_SETUP.md`: Google Sign-In setup guide
- `FIXING_GOOGLE_SIGNIN.md`: Troubleshooting SHA-1 issues
- `GET_API_KEYS.md`: API key retrieval guide
- `FEATURES.md`: This file - current features and roadmap

## Contact & Support
For issues or questions, refer to the documentation files or check the Firebase Console for configuration issues.

---
**Last Updated**: October 1, 2025
**Version**: 1.0.0 (MVP)
