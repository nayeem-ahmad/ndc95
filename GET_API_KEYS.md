# 🔑 How to Get Firebase API Keys

The `firebase_options.dart` file has been created with placeholders. You need to replace the API keys with your actual keys from Firebase Console.

## 📱 Get Android API Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **NDC95** project
3. Click the ⚙️ gear icon → **Project settings**
4. Scroll down to **Your apps** section
5. Click on the **Android app** (com.example.login_app)
6. You'll see the configuration - look for `current_key` under `api_key`
7. Copy the API key

**OR** download the `google-services.json` file:
- Click **Download google-services.json**
- Open the file
- Find `"current_key":` value under `api_key`
- That's your Android API key!

## 🌐 Get Web API Key

1. In Firebase Console → **Project settings**
2. Scroll to **Your apps** section
3. Click on the **Web app** (ndc95 (web))
4. You'll see a config object with `apiKey`
5. Copy that value

## 🍎 Get iOS API Key (Optional - for later)

1. In Firebase Console → **Project settings**
2. Click on **iOS app** (if you added one)
3. Download `GoogleService-Info.plist`
4. Open the file and find `API_KEY`
5. Copy that value

---

## ✏️ Update the firebase_options.dart File

Replace these placeholders in `/Users/bs01621/ndc95/lib/firebase_options.dart`:

```dart
// For Android
apiKey: 'YOUR_ANDROID_API_KEY',  // Replace with actual key

// For Web
apiKey: 'YOUR_WEB_API_KEY',      // Replace with actual key

// For iOS (if needed)
apiKey: 'YOUR_IOS_API_KEY',      // Replace with actual key
```

---

## 🚀 Quick Method - Download Config Files

### For Android:
1. Firebase Console → Project Settings → Android app
2. Click **Download google-services.json**
3. Place it in `android/app/` directory (already done by FlutterFire)
4. Get the API key from inside this file

### For Web:
1. Firebase Console → Project Settings → Web app
2. Copy the config object shown
3. Use the `apiKey` value from there

---

## 📝 Example

If your Android API key is: `AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q`

Change this:
```dart
apiKey: 'YOUR_ANDROID_API_KEY',
```

To this:
```dart
apiKey: 'AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q',
```

---

**After updating the API keys, we can initialize Firebase and start using authentication!** 🔥
