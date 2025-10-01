# Firebase Storage Setup for Profile Pictures

## Current Status

The profile picture upload feature is fully implemented and working, but you're seeing this error:

```
Error uploading profile picture: [firebase_storage/object-not-found] No object exists at the desired reference.
```

This happens because Firebase Storage rules need to be configured.

## Steps to Configure Firebase Storage

### 1. Enable Firebase Storage

1. Go to the Firebase Console: https://console.firebase.google.com/project/ndc95-9af5f/overview
2. Click on **Storage** in the left sidebar (under Build section)
3. Click **Get Started**
4. When prompted about security rules, click **Next**
5. Select your Cloud Storage location (choose the same region as your Firestore)
6. Click **Done**

### 2. Configure Security Rules

After enabling Storage, you need to set up security rules to allow users to upload their profile pictures.

1. In the Firebase Console, go to **Storage** → **Rules**
2. Replace the default rules with these:

```
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    // Allow users to read any profile picture
    match /profile_pictures/{userId}.jpg {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Ensure file is a JPEG image and less than 5MB
    match /profile_pictures/{userId}.jpg {
      allow write: if request.auth != null 
                   && request.auth.uid == userId
                   && request.resource.contentType.matches('image/jpeg')
                   && request.resource.size < 5 * 1024 * 1024;
    }
  }
}
```

3. Click **Publish** to apply the rules

### What These Rules Do

- **Read access**: Anyone can view profile pictures (public read)
- **Write access**: Only the owner of a profile can upload/update their own picture
- **File validation**: 
  - Must be a JPEG image
  - Must be less than 5MB
  - Filename must match the user's UID

## Testing the Feature

After configuring the rules:

1. Run the app on your emulator
2. Sign in with Google
3. Go to "My Profile" tab
4. Tap the camera icon on the profile picture
5. Choose "Camera" or "Gallery"
6. Take/select a photo
7. Crop the image to a square
8. The photo will upload to Firebase Storage

## Troubleshooting

### Error: "Object does not exist at location"
This means Storage is not enabled yet. Follow Step 1 above.

### Error: "Permission denied"
This means the security rules are not configured correctly. Follow Step 2 above.

### Error: "Unknown or invalid type"
Make sure you're uploading a JPEG image. The app converts images to JPEG automatically.

### Upload is slow
Firebase Storage upload speed depends on:
- Your internet connection
- Image file size
- Firebase Storage location

The app uses 80% image quality to balance size and quality.

## Storage Structure

Profile pictures are stored at:
```
gs://ndc95-9af5f.appspot.com/profile_pictures/{userId}.jpg
```

Where `{userId}` is the Firebase Auth user ID.

## Costs

Firebase Storage free tier includes:
- 5GB stored
- 1GB/day downloaded
- 20,000 uploads per day
- 50,000 downloads per day

Profile pictures are small (typically < 500KB), so you can support thousands of users within the free tier.

## Next Steps

1. Enable Firebase Storage in the console
2. Configure security rules as shown above
3. Test the upload feature
4. (Optional) Set up automatic thumbnail generation using Cloud Functions

## Related Documentation

- [Firebase Storage Security Rules](https://firebase.google.com/docs/storage/security)
- [Image Optimization Best Practices](https://firebase.google.com/docs/storage/best-practices)
