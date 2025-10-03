# Firebase Cloud Functions Setup Guide

## Overview
This guide explains how to set up Firebase Cloud Functions to send verification code emails automatically.

---

## Prerequisites

1. **Firebase Project** with Blaze (Pay-as-you-go) plan
   - Cloud Functions require the Blaze plan
   - Don't worry: There's a generous free tier (2M invocations/month)

2. **Node.js** installed (v18 or later)
   ```bash
   node --version  # Should be 18+
   ```

3. **Firebase CLI** installed
   ```bash
   npm install -g firebase-tools
   firebase --version
   ```

4. **Gmail Account** for sending emails
   - You'll need to generate an App Password

---

## Step 1: Upgrade to Blaze Plan

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **ndc95**
3. Click **⚙️ Settings** → **Usage and billing**
4. Click **Modify plan** → Select **Blaze (Pay as you go)**
5. Enter billing information
6. Confirm upgrade

**Note:** You'll stay within the free tier unless you have high traffic.

---

## Step 2: Set Up Gmail App Password

### Why App Password?
Google doesn't allow regular passwords for third-party apps. You need to generate a special App Password.

### Steps:

1. **Enable 2-Factor Authentication** (if not already)
   - Go to [myaccount.google.com/security](https://myaccount.google.com/security)
   - Enable 2-Step Verification

2. **Generate App Password**
   - Go to [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
   - Select app: **Mail**
   - Select device: **Other (Custom name)**
   - Name it: **NDC95 Firebase Functions**
   - Click **Generate**
   - Copy the 16-character password (e.g., `abcd efgh ijkl mnop`)

3. **Save it securely** - you'll need it in the next step

---

## Step 3: Initialize Firebase Functions

### Navigate to project directory:
```bash
cd /Users/bs01621/ndc95
```

### Login to Firebase:
```bash
firebase login
```

### Initialize Functions (if not already done):
```bash
firebase init functions
```

**Select:**
- Language: **JavaScript**
- ESLint: **Yes**
- Install dependencies: **Yes**

---

## Step 4: Install Dependencies

```bash
cd functions
npm install
```

This installs:
- `firebase-admin` - Firebase Admin SDK
- `firebase-functions` - Cloud Functions SDK
- `nodemailer` - Email sending library

---

## Step 5: Configure Email Credentials

### Set environment variables in Firebase:

```bash
# Replace with your Gmail address
firebase functions:config:set email.user="your.email@gmail.com"

# Replace with your Gmail App Password (remove spaces)
firebase functions:config:set email.password="abcdefghijklmnop"
```

### Verify configuration:
```bash
firebase functions:config:get
```

You should see:
```json
{
  "email": {
    "user": "your.email@gmail.com",
    "password": "abcdefghijklmnop"
  }
}
```

---

## Step 6: Deploy Cloud Functions

### Deploy all functions:
```bash
firebase deploy --only functions
```

This deploys:
1. `sendVerificationEmail` - Triggers when code is created in Firestore
2. `cleanupExpiredCodes` - Runs every hour to delete expired codes
3. `sendTestVerificationEmail` - HTTP endpoint for testing

### Expected output:
```
✔ functions: Finished running predeploy script.
i functions: preparing functions directory for uploading...
i functions: packaged functions (XX KB) for uploading
✔ functions: functions folder uploaded successfully
i functions: creating Node.js 18 function sendVerificationEmail...
✔ functions[sendVerificationEmail]: Successful create operation.
i functions: creating Node.js 18 function cleanupExpiredCodes...
✔ functions[cleanupExpiredCodes]: Successful create operation.

✔ Deploy complete!
```

---

## Step 7: Deploy Firestore Security Rules

### Deploy the security rules:
```bash
firebase deploy --only firestore:rules
```

### Verify in Firebase Console:
1. Go to **Firestore Database** → **Rules**
2. You should see the new rules
3. Check for any syntax errors

---

## Step 8: Update Firebase Configuration (Important!)

The firebase.json might need functions configuration:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": {
    "source": "functions",
    "codebase": "default",
    "runtime": "nodejs18"
  },
  "hosting": {
    "public": "web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ]
  }
}
```

---

## Step 9: Test Email Sending

### Method 1: Test through the app
1. Open the app
2. Try to sign in with an email
3. Check your email inbox
4. You should receive the verification code

### Method 2: Check Firebase Console Logs
```bash
firebase functions:log
```

Look for:
- `📧 Sending verification code to: user@example.com`
- `✅ Verification email sent successfully`

### Method 3: Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select **Functions** from left menu
3. Click on `sendVerificationEmail`
4. Check **Logs** tab for execution history

---

## Troubleshooting

### ❌ Error: "Firebase requires billing account"
**Solution:** Upgrade to Blaze plan (Step 1)

### ❌ Error: "Invalid login credentials"
**Causes:**
- Wrong Gmail App Password
- Regular password used instead of App Password
- Spaces in the password

**Solution:**
```bash
# Generate new App Password
# Set it again (remove all spaces):
firebase functions:config:set email.password="abcdefghijklmnop"

# Redeploy:
firebase deploy --only functions
```

### ❌ Error: "SMTP connection failed"
**Causes:**
- Gmail account has 2FA but no App Password
- Incorrect email address
- Gmail blocked the login attempt

**Solutions:**
1. Check Gmail account settings
2. Enable "Less secure app access" (not recommended)
3. Use App Password instead (recommended)
4. Check Firebase Functions logs for detailed error

### ❌ Emails not being sent
**Check:**
1. Firestore: Is code being created in `verificationCodes` collection?
2. Firebase Console → Functions → sendVerificationEmail → Logs
3. Check spam folder in email
4. Verify email configuration:
   ```bash
   firebase functions:config:get
   ```

### ❌ "Permission denied" errors
**Solution:** Deploy security rules:
```bash
firebase deploy --only firestore:rules
```

---

## Monitoring & Costs

### Monitor function executions:
1. Firebase Console → **Functions**
2. View graphs for invocations, errors, and execution time

### Check costs:
1. Firebase Console → **Usage and billing**
2. Most usage will be within free tier:
   - **Cloud Functions:** 2M invocations/month free
   - **Outbound Networking:** 5GB/month free

### Estimated costs (for reference):
- Sending 1,000 verification emails/month: **~$0**
- Sending 10,000 verification emails/month: **~$0.40**
- Sending 100,000 verification emails/month: **~$4.00**

---

## Alternative Email Services

If you don't want to use Gmail, here are alternatives:

### SendGrid (Recommended for production)
- 100 emails/day free forever
- Better deliverability
- Detailed analytics

**Setup:**
1. Sign up at [sendgrid.com](https://sendgrid.com)
2. Get API key
3. Update `functions/index.js`:
   ```javascript
   const sgMail = require('@sendgrid/mail');
   sgMail.setApiKey(functions.config().sendgrid.apikey);
   ```

### AWS SES
- Very cheap ($0.10 per 1,000 emails)
- Requires AWS account
- Good for high volume

### Mailgun
- 5,000 emails/month free for 3 months
- Then $35/month

---

## Security Best Practices

### 1. Never commit credentials
The `functions:config` is stored securely in Firebase, not in your code.

### 2. Rotate App Passwords periodically
Generate new App Password every 6-12 months:
```bash
firebase functions:config:set email.password="newpassword"
firebase deploy --only functions
```

### 3. Monitor for abuse
Set up alerts in Firebase Console if:
- Too many function invocations
- High error rates
- Unusual patterns

### 4. Rate limiting (optional)
Add rate limiting to prevent spam:
```javascript
// In functions/index.js
const rateLimit = require('express-rate-limit');
```

---

## Production Checklist

Before going to production:

- [ ] Blaze plan enabled
- [ ] Gmail App Password configured
- [ ] Functions deployed successfully
- [ ] Security rules deployed
- [ ] Test email sending works
- [ ] Check spam folder filtering
- [ ] Set up monitoring alerts
- [ ] Test error scenarios (invalid email, etc.)
- [ ] Review Firebase usage dashboard
- [ ] Remove "Show Code" button from app ✅ (already done)
- [ ] Update email template with your branding
- [ ] Test on multiple email providers (Gmail, Outlook, Yahoo, etc.)

---

## Quick Commands Reference

```bash
# Deploy everything
firebase deploy

# Deploy only functions
firebase deploy --only functions

# Deploy only rules
firebase deploy --only firestore:rules

# View logs
firebase functions:log

# View config
firebase functions:config:get

# Set config
firebase functions:config:set email.user="your@email.com"
firebase functions:config:set email.password="your-app-password"

# Delete config
firebase functions:config:unset email

# Test locally (requires emulator)
firebase emulators:start --only functions

# Update dependencies
cd functions && npm update
```

---

## Support

**If you encounter issues:**
1. Check [Firebase Functions documentation](https://firebase.google.com/docs/functions)
2. Review [Nodemailer documentation](https://nodemailer.com/)
3. Check Firebase Console logs
4. Review this guide's troubleshooting section

**Common resources:**
- Firebase Console: https://console.firebase.google.com
- Gmail App Passwords: https://myaccount.google.com/apppasswords
- Firebase CLI docs: https://firebase.google.com/docs/cli

---

**Last Updated:** October 3, 2025  
**Version:** 1.0 - Production Email Setup
