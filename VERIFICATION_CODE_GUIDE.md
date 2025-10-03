# Verification Code Retrieval Guide

## Overview
Since the app doesn't currently send verification codes via email, this guide explains how to retrieve verification codes during development and testing.

## How Verification Codes Work

When you request a verification code (sign-in, sign-up, or Student ID authentication), the system:

1. ✅ Generates a random 6-digit code
2. ✅ Stores it in **Firestore** (collection: `verificationCodes`)
3. ✅ Stores it in **memory** (for validation)
4. ✅ Prints it to the **console** (if you have debug access)
5. ❌ Does NOT send via email (not implemented yet)

## Method 1: Using the "Show Code" Button (Easiest)

On the verification screen, there's an orange **"Show Code (Dev Mode)"** button.

**Steps:**
1. Enter your email and click "Sign In"
2. You'll be taken to the verification screen
3. Click the orange **"Show Code (Dev Mode)"** button
4. A dialog will show your 6-digit code
5. Click **"Auto-Fill Code"** to automatically enter it, or manually type it

**Screenshot of what to look for:**
```
┌─────────────────────────────┐
│  [Resend Code]              │
│                             │
│  [📟 Show Code (Dev Mode)]  │  ← Click this!
│                             │
│  ⚠️ Check your spam folder  │
└─────────────────────────────┘
```

---

## Method 2: Check Firestore Database

If the button doesn't work, you can manually check Firestore.

**Steps:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **ndc95**
3. Navigate to **Firestore Database**
4. Open the **`verificationCodes`** collection
5. Find the document with your email address (e.g., `user@example.com`)
6. Look at the **`code`** field - that's your 6-digit code
7. Enter it in the app

**Firestore Structure:**
```
verificationCodes/
  └── user@example.com/
      ├── code: "123456"
      ├── email: "user@example.com"
      ├── createdAt: Timestamp
      └── expiresAt: "2024-10-03T15:30:00"
```

---

## Method 3: Check Console Logs (Advanced)

If you're running the app from VS Code or terminal:

**Steps:**
1. Look at your terminal/console output
2. After requesting a code, you'll see:
   ```
   ✅ Verification code stored in Firestore for user@example.com: 123456
   📧 Verification code for user@example.com: 123456
   ⏰ Code expires in 10 minutes
   ```
3. Copy the 6-digit code
4. Enter it in the app

---

## Common Issues & Solutions

### ❌ "No verification code found in database"

**Causes:**
- Code expired (10-minute limit)
- Code was already used
- Network error during code generation

**Solutions:**
1. Click **"Resend Code"** on the verification screen
2. Wait 60 seconds for the cooldown
3. Try clicking "Show Code (Dev Mode)" again

---

### ❌ "Invalid verification code"

**Causes:**
- Typed wrong code
- Code expired
- Using an old code

**Solutions:**
1. Click "Show Code (Dev Mode)" to see current code
2. Make sure you're entering all 6 digits correctly
3. Request a new code if it's been more than 10 minutes

---

### ❌ Can't see the button

**Solutions:**
1. Make sure you're on the **Email Verification Screen** (after entering email)
2. Scroll down - the button is below "Resend Code"
3. Update the app to the latest version

---

## Code Expiration

⏰ **Verification codes expire after 10 minutes**

If your code expired:
1. Click **"Resend Code"**
2. Wait for the 60-second cooldown
3. A new code will be generated
4. Use "Show Code (Dev Mode)" to see the new code

---

## For Production Use

**⚠️ Important:** The current system is for **development/testing only**.

**For production, you should:**

1. **Option A: Firebase Functions + Email Service**
   - Set up Firebase Functions
   - Integrate SendGrid, AWS SES, or Mailgun
   - Send actual emails with codes
   - Remove the "Show Code" button

2. **Option B: SMS Verification**
   - Use Twilio or Firebase Phone Auth
   - Send codes via SMS instead of email

3. **Option C: Firebase Email Extension**
   - Install the "Trigger Email" Firebase Extension
   - Configure with your email provider
   - Automatically send emails from Firestore triggers

---

## Testing Different Scenarios

### Test Email Sign-In
1. Create account with email: `test@example.com`
2. Sign out
3. Go to Sign In screen
4. Enter email: `test@example.com`
5. Click "Sign In with Email"
6. Use "Show Code (Dev Mode)" to get verification code
7. Enter code and password

### Test Student ID Sign-In
1. Enter existing Student ID: `95301023`
2. See masked email: `na****@gmail.com`
3. Confirm sending code
4. Use "Show Code (Dev Mode)" to get verification code
5. Enter code to verify

### Test Email Sign-Up
1. Click "Sign Up" from Sign In screen
2. Choose "Sign Up with Email"
3. Fill in details
4. Use "Show Code (Dev Mode)" on verification screen
5. Set password and complete signup

---

## Quick Reference Card

| **Need**                  | **Action**                          |
|---------------------------|-------------------------------------|
| 🔍 Find my code           | Click "Show Code (Dev Mode)" button |
| 📱 Auto-fill code         | Click "Auto-Fill Code" in dialog    |
| 🔄 Get new code           | Click "Resend Code" (60s cooldown)  |
| 💾 Check database         | Firebase Console > verificationCodes|
| 👁️ See in console         | Check terminal output               |
| ⏰ Code expired           | Request new code                    |

---

## Developer Notes

**Files Modified:**
- `lib/services/auth_service.dart` - Stores codes in Firestore
- `lib/screens/email_verification_screen.dart` - Added "Show Code" button
- `lib/screens/signin_screen.dart` - Shows success message with instructions

**Firestore Security Rules:**
Make sure users can read their own verification codes:
```javascript
match /verificationCodes/{email} {
  allow read: if request.auth != null;
  allow write: if false; // Only server can write
}
```

---

## Support

If you're still having issues:
1. Check that you have internet connection
2. Verify you're signed in to the correct Firebase project
3. Check Firebase Console for any error messages
4. Clear app data and try again
5. Review console logs for error messages

---

**Last Updated:** October 3, 2025  
**Version:** 2.1 - Development Mode with Firestore Codes
