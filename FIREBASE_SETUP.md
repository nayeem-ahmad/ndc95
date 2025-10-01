# 🔥 Firebase Setup Instructions for NDC95

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: **NDC95**
4. Accept terms and click **Continue**
5. Disable Google Analytics (optional) or link account
6. Click **Create project**

## Step 2: Configure Firebase for Flutter

Once your Firebase project is created, run this command in your terminal:

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
cd /Users/bs01621/ndc95
flutterfire configure
```

This will:
- Detect your Flutter platforms (Android, iOS, web, etc.)
- Create `firebase_options.dart` file
- Configure your Firebase project for all platforms

**Select these options when prompted:**
- Select your Firebase project: **NDC95**
- Select platforms: **Android, iOS, Web** (use spacebar to select, enter to confirm)

## Step 3: Enable Authentication Methods

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable these providers:
   - ✅ **Email/Password** (for current login)
   - ✅ **Phone** (for SMS verification)

### For Phone Authentication:
1. Click on **Phone** provider
2. Enable it
3. Add test phone numbers if needed (for development)

## Step 4: Create Firestore Database

1. Go to **Firestore Database** in Firebase Console
2. Click **Create database**
3. Start in **Test mode** (we'll add security rules later)
4. Choose a location closest to your users
5. Click **Enable**

## Step 5: Set Up Firebase Storage

1. Go to **Storage** in Firebase Console
2. Click **Get started**
3. Start in **Test mode**
4. Click **Done**

## Step 6: Enable Cloud Messaging (Push Notifications)

1. Go to **Project Settings** → **Cloud Messaging**
2. Under **Cloud Messaging API (Legacy)**, enable it if disabled
3. For Android: Note down the **Server Key** (optional for now)

## Step 7: Update Android Configuration (for Phone Auth)

Edit `android/app/build.gradle.kts` and ensure minSdk is at least 21:

```kotlin
android {
    defaultConfig {
        minSdk = 21  // Make sure this is 21 or higher
    }
}
```

## Step 8: Verify Setup

Run the app and you should see Firebase initialized!

```bash
flutter run -d emulator-5554
```

---

## 🎯 Next Steps After Setup:

Once Firebase is configured, we'll:
1. ✅ Integrate Firebase Authentication with the login screen
2. ✅ Add phone number verification
3. ✅ Set up push notifications
4. ✅ Create user directory with Firestore
5. ✅ Add photo/video upload to Firebase Storage

---

## 📝 Notes:

- Firebase free tier is very generous - you won't pay anything initially
- Test mode security rules are open - we'll secure them before production
- Phone authentication costs ~$0.01-0.02 per SMS

---

**After completing these steps, let me know and I'll integrate Firebase into your app!** 🚀
