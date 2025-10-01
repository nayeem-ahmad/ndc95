# 🔧 Fixing Google Sign-In Error 10

You're seeing this error because the app needs to be properly configured with Google Cloud. Here's how to fix it:

## Error Code 10: Developer Error

This means the Android app isn't properly registered with your Firebase project's SHA-1 certificate.

---

## 🔑 Step 1: Get Your SHA-1 Certificate Fingerprint

### Method 1: Using Flutter (Easiest)

Run this in your terminal:

```bash
cd /Users/bs01621/ndc95
flutter build apk
```

Then check the build output - it will show the SHA-1 fingerprint.

### Method 2: Using Gradle Signing Report

```bash
cd /Users/bs01621/ndc95/android
./gradlew signingReport
```

Look for the **debug** variant section and find the SHA1 line.

### Method 3: From Android Studio

1. Open the project in Android Studio
2. Click **Gradle** tab on the right
3. Navigate to: `android` → `Tasks` → `android` → `signingReport`
4. Double-click to run
5. Look for SHA1 in the output

### Method 4: Get from Firebase CLI

Since FlutterFire already registered your app, you can also:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select **NDC95** project
3. Project Settings → Your Android app
4. The SHA certificate fingerprints section is at the bottom

If it's empty, you need to add one!

---

## 🔥 Step 2: Add SHA-1 to Firebase Console (IMPORTANT!)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **NDC95** project
3. Click the ⚙️ gear icon → **Project Settings**
4. Scroll down to **Your apps** section
5. Find your Android app: `com.nayeemahmad.ndc95`
6. Scroll down to **SHA certificate fingerprints**
7. Click **Add fingerprint**
8. Paste your SHA-1 certificate
9. Click **Save**

**This is the most important step!**

---

## ✅ Step 3: Verify Google Sign-In is Enabled

1. In Firebase Console, go to **Authentication**
2. Click **Sign-in method** tab
3. Find **Google** in the providers list
4. Make sure it shows **Enabled**
5. If not:
   - Click on Google
   - Toggle **Enable**
   - Add your support email
   - Click **Save**

---

## � Step 4: Download Updated Config (Optional but Recommended)

1. In Project Settings → Your Android app
2. Click **Download google-services.json**
3. Replace the file at: `/Users/bs01621/ndc95/android/app/google-services.json`

---

## 🔄 Step 5: Rebuild and Test

```bash
cd /Users/bs01621/ndc95
flutter clean
flutter pub get
flutter run -d emulator-5554
```

---

## 🚀 Alternative: Let FlutterFire Configure Everything

Run this command and it should automatically configure everything:

```bash
cd /Users/bs01621/ndc95
flutterfire configure --project=ndc95-9af5f
```

This will automatically:
- Register your app
- Add SHA certificates
- Configure OAuth clients

---

## ❓ Common Issues

### "Error 10" still appears after adding SHA-1?

1. **Wait 5-10 minutes** - Changes need time to propagate
2. **Clear app data** on the emulator:
   ```
   Settings → Apps → Your app → Clear Data
   ```
3. **Restart the emulator**
4. **Try adding SHA-256** fingerprint too (shown in signing report)

### Can't find SHA-1?

If you can't run the commands, you can:
1. Build the app: `flutter build apk`
2. Check the build logs for the SHA-1
3. Or use Firebase Console to generate one automatically

**Note:** The app package name is now `com.nayeemahmad.ndc95`

---

## 📝 Why This Happens

Google Sign-In uses OAuth 2.0 which requires:
- ✅ App package name registered (`com.nayeemahmad.ndc95`)
- ✅ SHA-1 certificate registered  ← **THIS IS MISSING**
- ✅ OAuth client created (automatic)
- ✅ Sign-in method enabled

The SHA-1 proves your app is legitimate and not malicious.

---

## 🎯 Quick Fix Checklist

- [ ] Get SHA-1 fingerprint (use any method above)
- [ ] Add SHA-1 to Firebase Console (Project Settings → Android app)
- [ ] Verify Google Sign-In is enabled (Authentication → Sign-in method)
- [ ] Download new google-services.json
- [ ] Run `flutter clean && flutter pub get`
- [ ] Rebuild and test

**Once you add the SHA-1 to Firebase Console, the sign-in should work!** 🔥
