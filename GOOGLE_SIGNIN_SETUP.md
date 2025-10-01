# 🔐 Google Sign-In Setup for NDC95

To enable Google Sign-In in your app, follow these steps:

## 📱 Step 1: Enable Google Sign-In in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **NDC95** project
3. Navigate to **Authentication** → **Sign-in method**
4. Click on **Google** in the providers list
5. Toggle the **Enable** switch
6. Enter your project support email (e.g., nayeem.ahmad@gmail.com)
7. Click **Save**

That's it! Google Sign-In is now enabled for your Firebase project.

---

## 🤖 Step 2: Configure Android (Already Done!)

The FlutterFire CLI has already configured your Android app with:
- ✅ SHA-1 certificate fingerprint
- ✅ OAuth 2.0 client ID

Your `google-services.json` file contains all the necessary configuration.

---

## 🍎 Step 3: Configure iOS (Optional - For iOS Support)

If you want to support iOS:

1. In Firebase Console → **Project Settings**
2. Scroll to **Your apps** section
3. Click on your iOS app
4. Download `GoogleService-Info.plist`
5. Add it to `ios/Runner/` directory in Xcode

Then add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
    </array>
  </dict>
</array>
```

Replace `YOUR-CLIENT-ID` with the reversed client ID from `GoogleService-Info.plist`.

---

## 🌐 Step 4: Test Google Sign-In

1. Run your app on Android emulator:
   ```bash
   flutter run -d emulator-5554
   ```

2. On the login screen, click **"Continue with Google"**

3. Select your Google account

4. You should see a success message!

---

## 🎯 What Happens During Google Sign-In?

1. **User clicks "Continue with Google"**
2. Google Sign-In dialog appears
3. User selects/signs into their Google account
4. App receives Google credentials
5. Firebase creates/signs in the user
6. If new user → User profile created in Firestore
7. Success message displayed

---

## 🔧 Troubleshooting

### "Sign in failed" or "API not enabled"

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your NDC95 project
3. Go to **APIs & Services** → **Library**
4. Search for "Google+ API" or "People API"
5. Enable it

### "Error 10: Developer error"

1. Firebase Console → Project Settings → Your Android app
2. Add your SHA-1 certificate fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
3. Copy the SHA-1 fingerprint
4. Add it in Firebase Console
5. Download new `google-services.json`

### "No user returned"

The user canceled the sign-in. This is normal behavior.

---

## ✅ Features Added

- ✅ Google Sign-In button with Google logo
- ✅ Automatic user profile creation in Firestore
- ✅ Error handling for failed sign-ins
- ✅ Loading state during authentication
- ✅ Welcome message with user's name

---

**After enabling Google Sign-In in Firebase Console, you can test it immediately!** 🚀
