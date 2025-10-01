# Firestore Database Setup

## Issue
The app is showing `PERMISSION_DENIED` errors because Cloud Firestore API is not enabled.

## Solution

### Step 1: Enable Cloud Firestore API

1. **Quick Enable Link:**
   - Visit: https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=ndc95-9af5f
   - Click "Enable"

2. **Or via Firebase Console:**
   - Go to: https://console.firebase.google.com/
   - Select project: `ndc95-9af5f`
   - Click "Firestore Database" in left menu
   - Click "Create database"
   - Choose location closest to you
   - Select "Test mode" for now (we'll secure it later)
   - Click "Enable"

### Step 2: Set Up Security Rules

After enabling Firestore, go to **Firestore Database** → **Rules** tab and use these rules:

**For Development (Test Mode - Allow All):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 12, 31);
    }
  }
}
```

**For Production (Authenticated Users Only):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - users can only read/write their own data
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Posts collection - authenticated users can create/read
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Albums collection - authenticated users can create/read
    match /albums/{albumId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

### Step 3: Verify Firestore is Working

After enabling:
1. Wait 1-2 minutes for the API to propagate
2. Restart your app: `flutter run -d emulator-5554`
3. Sign in with Google
4. Check Firebase Console → Firestore Database → Data tab
5. You should see a `users` collection with your user document

## Note About Google Play Services Errors

The emulator may show these warnings (they're usually harmless):
```
DEVELOPER_ERROR: API: Phenotype.API is not available on this device
SecurityException: Unknown calling package name 'com.google.android.gms'
```

These are common on Android emulators and typically don't affect Google Sign-In functionality. If Google Sign-In still doesn't work after enabling Firestore:

1. Make sure Google Play Store is installed on your emulator
2. Try updating Google Play Services in the emulator
3. Or test on a real Android device

## Current Status
- ✅ Google Sign-In configured with OAuth credentials
- ✅ SHA-1 certificate registered
- ⏳ **Firestore API needs to be enabled** ← Do this now!
- ⏳ Security rules need to be configured
