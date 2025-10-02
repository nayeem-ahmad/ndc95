# NDC95 App - Testing Guide

## 📦 APK Download

**File**: `app-release.apk`  
**Location**: `/Users/bs01621/ndc95/build/app/outputs/flutter-apk/app-release.apk`  
**Size**: 21.6 MB  
**Build Date**: October 2, 2025  
**Version**: Production Release Build  
**Platform**: Android (ARM64)

## 📱 Installation Instructions

### Prerequisites
- Android device (Android 5.0 or higher recommended)
- Allow installation from unknown sources

### Steps to Install

1. **Enable Unknown Sources** (if not already enabled)
   - Go to **Settings** → **Security** (or **Privacy**)
   - Enable **"Install unknown apps"** or **"Unknown sources"**
   - Or enable it when prompted during installation

2. **Transfer APK to Phone**
   - **Via USB**: Connect phone to computer and copy the APK file
   - **Via Email**: Email the APK to yourself and download on phone
   - **Via Cloud**: Upload to Google Drive/Dropbox and download on phone
   - **Via AirDrop** (if available): Send directly to phone

3. **Install the APK**
   - Open the APK file from your phone's file manager or downloads
   - Tap **"Install"**
   - Wait for installation to complete
   - Tap **"Open"** to launch the app

## 🧪 Testing Checklist

### 1. **Initial Setup & Login**
- [ ] App launches successfully
- [ ] Login screen displays correctly
- [ ] **Google Sign-In** button works
- [ ] **Email Sign-Up** button works

### 2. **Google Sign-In Flow**
- [ ] Can select Google account
- [ ] Successfully signs in
- [ ] Redirects to home screen
- [ ] Profile shows correct name and email
- [ ] Profile picture displays (if available)

### 3. **Email Sign-Up Flow (New User)**
- [ ] Click "Sign Up with Email"
- [ ] Enter email address
- [ ] Receives verification code prompt
- [ ] **Note**: Check console/logs for code (dev mode)
- [ ] Enter 6-digit code successfully
- [ ] Navigate to password setup screen
- [ ] Enter full name
- [ ] Create password (min 6 chars)
- [ ] Confirm password
- [ ] Account created successfully
- [ ] Navigate to home screen

### 4. **Email Sign-In Flow (Existing User)**
- [ ] Enter registered email
- [ ] Receive verification code
- [ ] Enter code successfully
- [ ] Enter password
- [ ] Successfully sign in
- [ ] Navigate to home screen

### 5. **Home Screen Navigation**
- [ ] Bottom navigation bar displays
- [ ] **Directory** tab works
- [ ] **My Profile** tab works
- [ ] **Admin** tab visible (for admins only)
- [ ] Switch between tabs smoothly

### 6. **Directory Features**
- [ ] Member list loads
- [ ] Search bar works
- [ ] Filter by group works
- [ ] Member cards display correctly
- [ ] Click member to view details
- [ ] Profile pictures load

### 7. **Profile Screen**
- [ ] Current user info displays
- [ ] Edit profile button works
- [ ] Can update profile picture
- [ ] Can edit name, phone, address
- [ ] Can save changes
- [ ] Changes persist after logout

### 8. **Admin Features** (For Admin/SuperAdmin Only)
- [ ] Admin tab appears in navigation
- [ ] Role info card displays correct role
- [ ] **Manage Members** button works
- [ ] Can see member list
- [ ] Can add new member
- [ ] Can edit member details
- [ ] Can delete member
- [ ] Email uniqueness validation works
- [ ] **Role assignment** (SuperAdmin only)
  - [ ] Purple shield icon visible
  - [ ] Role dialog opens
  - [ ] Can assign different roles
  - [ ] Role updates successfully
  - [ ] Role badge shows on member card

### 9. **Group Admin Features** (For Group Admins)
- [ ] Admin tab appears
- [ ] Only sees members from own group
- [ ] Can add members to own group
- [ ] Can edit group members
- [ ] Can delete group members
- [ ] Cannot see other groups
- [ ] Cannot assign roles

### 10. **Sign Out**
- [ ] Sign out button in app bar works
- [ ] Returns to login screen
- [ ] Cannot access app without login

### 11. **Offline Behavior**
- [ ] App handles no internet gracefully
- [ ] Shows appropriate error messages
- [ ] Cached data displays when offline

### 12. **Performance**
- [ ] App launches quickly
- [ ] Screens load without delay
- [ ] Smooth scrolling in lists
- [ ] No crashes or freezes
- [ ] Images load efficiently

## 🐛 Bug Reporting

If you encounter any issues, please report with:

### Bug Report Template
```
**Description**: Brief description of the issue

**Steps to Reproduce**:
1. Step 1
2. Step 2
3. Step 3

**Expected Behavior**: What should happen

**Actual Behavior**: What actually happened

**Screenshots**: (if applicable)

**Device Info**:
- Device Model: (e.g., Samsung Galaxy S21)
- Android Version: (e.g., Android 12)
- App Version: Production Release (Oct 2, 2025)

**Additional Notes**: Any other relevant information
```

## 📝 Known Limitations (Development Build)

1. **Email Verification Codes**
   - Currently logged to console only
   - For testing: Check developer logs or ask admin for code
   - Production will send actual emails

2. **Google Play Services**
   - Some warnings in logs are normal for development builds
   - Will be resolved in production Play Store release

3. **App Signing**
   - APK is signed with development key
   - Play Store version will use production signing

## ✅ Success Criteria

The app is working correctly if:
- ✅ Login works (Google or Email)
- ✅ Can view member directory
- ✅ Can edit own profile
- ✅ Navigation is smooth
- ✅ No crashes during normal use
- ✅ Admin features work (if admin user)

## 🔐 Test Accounts

### SuperAdmin Account
- **Email**: nayeem.ahmad@gmail.com
- **Method**: Google Sign-In
- **Access**: Full access to all features

### Regular Member
- **Method**: Any Google account or email signup
- **Access**: View directory, edit own profile

## 📊 Features to Test

### Core Features
1. **Authentication**: Google Sign-In, Email Sign-Up, Email Sign-In
2. **Directory**: View members, search, filter
3. **Profile Management**: View, edit own profile
4. **Role-Based Access**: Different views for different roles

### Admin Features (SuperAdmin/Admin)
1. **Member Management**: Add, edit, delete members
2. **Email Validation**: Unique email enforcement
3. **Role Assignment**: Assign roles (SuperAdmin only)
4. **CSV Import**: Bulk member import

### Group Admin Features
1. **Group Management**: Manage own group only
2. **Member Management**: Add, edit, delete group members

## 📞 Contact

**Developer**: Nayeem Ahmad  
**Email**: nayeem.ahmad@gmail.com  
**Repository**: github.com/nayeem-ahmad/ndc95  

## 🎯 Feedback Areas

Please focus testing on:

1. **Login Experience**
   - Is it intuitive?
   - Any confusing steps?
   
2. **Navigation**
   - Easy to find features?
   - Tab switching smooth?

3. **Member Directory**
   - Search functionality
   - Filter by group
   - Profile details

4. **Profile Management**
   - Editing experience
   - Picture upload
   - Save functionality

5. **Admin Tools** (if applicable)
   - Member management workflow
   - Role assignment process
   - Any missing features?

## 🚀 Future Features (Coming Soon)

- [ ] Push notifications
- [ ] Group messaging
- [ ] Event management
- [ ] Photo gallery
- [ ] News feed
- [ ] Password reset via email
- [ ] Actual email delivery for verification codes
- [ ] Play Store release

## 📄 Documentation

For more details, see:
- **EMAIL_AUTHENTICATION.md** - Email signup details
- **ROLE_BASED_PERMISSIONS.md** - Role system documentation
- **MEMBER_MANAGEMENT_FEATURE.md** - Member management guide
- **README.md** - General app information

---

**Thank you for testing! Your feedback is valuable.** 🙏
