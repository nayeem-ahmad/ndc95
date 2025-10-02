# Email Authentication Feature

## Overview
Implemented comprehensive email-based authentication with verification code system, supporting both new user signup and existing user signin.

## Features

### 1. **Email Signup Flow**
- User enters email address
- System checks if email exists in database
- Verification code sent to email
- User enters 6-digit code
- New users: Set password and name
- Existing users: Enter password to sign in

### 2. **Email Verification**
- 6-digit verification code
- 10-minute expiration
- Resend functionality with 60-second cooldown
- Auto-submit when all digits entered
- Spam folder reminder

### 3. **Password Creation**
- Minimum 6 characters
- Password confirmation
- Display name required
- Secure Firebase storage

### 4. **Smart Authentication Detection**
- Detects Google vs Email signups
- Prevents duplicate accounts
- Seamless flow for existing users
- Clear error messages

## User Flows

### New User Signup (Email)
```
1. Click "Sign Up with Email" on login screen
2. Enter email address
3. Receive 6-digit verification code
4. Enter code in verification screen
5. Set display name
6. Create password (min 6 characters)
7. Confirm password
8. Account created → Navigate to home
```

### Existing User Signin (Email)
```
1. Click "Sign Up with Email" on login screen
2. Enter registered email
3. Receive verification code
4. Enter 6-digit code
5. Enter password
6. Sign in → Navigate to home
```

### Google vs Email Detection
```
If user registered with Google:
- Show message: "This email is registered with Google"
- Redirect to use Google Sign-In

If user registered with Email:
- Prompt for password after verification
- Sign in with email/password
```

## Screens

### 1. **Login Screen** (`main.dart`)
- **Google Sign-In Button**
  - White background
  - Google icon
  - "Continue with Google"
  
- **Divider**: "OR"
  
- **Email Sign-Up Button**
  - Blue outline
  - Email icon
  - "Sign Up with Email"

### 2. **Email Signup Screen** (`email_signup_screen.dart`)
- **Email input field**
  - Validation for email format
  - Required field
  
- **Continue button**
  - Checks if email exists
  - Sends verification code
  - Navigates to verification

- **Info box**
  - Explains existing email behavior

### 3. **Email Verification Screen** (`email_verification_screen.dart`)
- **6-digit code input**
  - Individual boxes for each digit
  - Auto-focus next field
  - Auto-submit when complete
  
- **Verify button**
  - Validates code
  - Checks expiration
  
- **Resend button**
  - 60-second cooldown
  - Clears existing code
  
- **Smart routing**
  - New user → Set Password Screen
  - Existing user → Password dialog
  - Google user → Error message

### 4. **Set Password Screen** (`set_password_screen.dart`)
- **Email display** (read-only)
- **Full name input** (required, min 2 chars)
- **Password input** (min 6 chars, toggle visibility)
- **Confirm password** (must match)
- **Create Account button**
  - Creates Firebase Auth account
  - Saves user profile to Firestore
  - Navigates to home

## Technical Implementation

### AuthService (`lib/services/auth_service.dart`)

#### Key Methods:

```dart
// Check if email exists in Firestore
static Future<bool> checkEmailExists(String email)

// Generate and send verification code
static Future<void> sendVerificationCode(String email)

// Verify code entered by user
static Future<bool> verifyCode(String email, String code)

// Sign in existing user
static Future<UserCredential> signInExistingUser(String email)

// Create new user with password
static Future<UserCredential> createUserWithPassword({
  required String email,
  required String password,
  String? displayName,
})

// Sign in with email and password
static Future<UserCredential> signInWithPassword({
  required String email,
  required String password,
})

// Resend verification code
static Future<void> resendVerificationCode(String email)

// Send password reset email
static Future<void> sendPasswordResetEmail(String email)
```

#### Verification Code System:
- **Storage**: In-memory map (for development)
- **Format**: 6-digit random number
- **Expiration**: 10 minutes
- **Production**: Should use Firebase Functions or backend email service

### Database Structure

#### User Document (Firestore):
```dart
{
  'email': 'user@example.com',           // Lowercase
  'displayName': 'John Doe',
  'hasPassword': true,                    // true for email signup
  'authProvider': 'email',                // 'email' or 'google'
  'photoUrl': '',
  'phoneNumber': '',
  'role': 'member',                       // User role
  'group': '6',                          // Group number (from Student ID)
  'createdAt': Timestamp,
  'updatedAt': Timestamp,
}
```

### Security Features

1. **Email Validation**
   - Regex pattern: `^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$`
   - Case-insensitive storage

2. **Code Expiration**
   - 10-minute timeout
   - Automatic cleanup after use

3. **Password Requirements**
   - Minimum 6 characters
   - Firebase Auth encryption
   - Confirmation required

4. **Duplicate Prevention**
   - Email uniqueness check
   - Provider detection (Google vs Email)
   - Clear error messages

## UI/UX Details

### Color Scheme
- **Google Button**: White with grey border
- **Email Button**: Blue outline (blue.shade400)
- **Verification**: Green theme (verification success)
- **Password Setup**: Purple theme (profile creation)

### Icons
- Google Sign-In: `Icons.g_mobiledata_rounded`
- Email Sign-Up: `Icons.email_outlined`
- Verification: `Icons.mark_email_read_outlined`
- Password Setup: `Icons.person_add_outlined`

### Loading States
- Spinner in button during API calls
- Disabled inputs while loading
- Countdown timer for resend

### Error Handling
- Validation errors inline (red text)
- Network errors via SnackBar
- Expired code detection
- Wrong password attempts

## Development vs Production

### Current Implementation (Development)
```dart
// Verification codes stored in memory
static final Map<String, String> _verificationCodes = {};

// Code logged to console
print('📧 Verification code for $email: $code');
```

### Production Requirements
1. **Email Service Integration**
   - SendGrid
   - AWS SES
   - Firebase Extensions (Trigger Email)
   
2. **Backend Functions**
   - Firebase Cloud Functions
   - Store codes in Firestore with TTL
   - Rate limiting for code requests
   
3. **Security Enhancements**
   - Implement rate limiting
   - Add CAPTCHA for signup
   - Monitor suspicious activity
   
4. **Email Templates**
   - Branded HTML templates
   - Include app logo
   - Clear instructions
   - Support contact

### Example Production Setup

#### Firebase Function (Node.js):
```javascript
const functions = require('firebase-functions');
const nodemailer = require('nodemailer');

exports.sendVerificationEmail = functions.https.onCall(async (data, context) => {
  const { email, code } = data;
  
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: 'noreply@ndc95.com',
      pass: process.env.EMAIL_PASSWORD
    }
  });

  const mailOptions = {
    from: 'NDC95 <noreply@ndc95.com>',
    to: email,
    subject: 'Your Verification Code - NDC95',
    html: `
      <h2>Welcome to NDC95!</h2>
      <p>Your verification code is:</p>
      <h1 style="color: #2196F3; letter-spacing: 5px;">${code}</h1>
      <p>This code expires in 10 minutes.</p>
    `
  };

  await transporter.sendMail(mailOptions);
  return { success: true };
});
```

#### Firestore Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Verification codes collection
    match /verification_codes/{email} {
      allow read, write: if request.auth != null;
      allow read: if resource.data.email == request.auth.token.email;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

## Testing Checklist

### New User Flow
- ✅ Email validation works
- ✅ Verification code sent (check console)
- ✅ Code expiration after 10 minutes
- ✅ Resend code functionality
- ✅ Password strength validation
- ✅ Password confirmation match
- ✅ Account created in Firebase Auth
- ✅ User profile created in Firestore
- ✅ Navigate to home after signup

### Existing User Flow
- ✅ Email detected as existing
- ✅ Verification code sent
- ✅ Password dialog appears
- ✅ Correct password signs in
- ✅ Wrong password shows error
- ✅ Navigate to home after signin

### Google User Detection
- ✅ Detects Google signup
- ✅ Shows appropriate error message
- ✅ Redirects to login screen

### Edge Cases
- ✅ Invalid email format
- ✅ Empty fields
- ✅ Password mismatch
- ✅ Expired verification code
- ✅ Wrong verification code
- ✅ Network errors handled
- ✅ Resend cooldown works

## Known Limitations

1. **Email Delivery**
   - Currently logs code to console
   - Production needs email service

2. **Code Storage**
   - In-memory (resets on restart)
   - Production needs persistent storage

3. **Rate Limiting**
   - No protection against abuse
   - Production needs request limits

4. **Password Reset**
   - Method exists but not integrated in UI
   - Add "Forgot Password" link

## Future Enhancements

- [ ] Email service integration (SendGrid/AWS SES)
- [ ] Forgot password flow
- [ ] Password reset in profile
- [ ] Email verification on Google signups
- [ ] Rate limiting and abuse protection
- [ ] CAPTCHA integration
- [ ] Email templates with branding
- [ ] SMS verification option
- [ ] Social auth (Facebook, Apple)
- [ ] Two-factor authentication
- [ ] Account recovery options
- [ ] Email change flow
- [ ] Login history tracking

## Files Created

1. **`lib/services/auth_service.dart`**
   - Email verification logic
   - Code generation and validation
   - Account creation methods

2. **`lib/screens/email_signup_screen.dart`**
   - Email input screen
   - Email validation
   - Navigation to verification

3. **`lib/screens/email_verification_screen.dart`**
   - 6-digit code input
   - Verification logic
   - Resend functionality
   - Smart routing

4. **`lib/screens/set_password_screen.dart`**
   - Name input
   - Password creation
   - Account finalization

## Files Modified

1. **`lib/main.dart`**
   - Added "Sign Up with Email" button
   - Added divider with "OR"
   - Updated imports

## Usage Instructions

### For Users
1. Open the app
2. Click "Sign Up with Email"
3. Enter your email address
4. Check console for verification code (development)
5. Enter the 6-digit code
6. If new user: Set name and password
7. If existing: Enter your password
8. Start using the app!

### For Developers
1. Monitor console for verification codes
2. Code format: `📧 Verification code for {email}: {code}`
3. Code expires in 10 minutes
4. Resend available after 60 seconds
5. Test with different scenarios:
   - New email
   - Existing email (with password)
   - Existing email (Google signup)

## Migration Guide

### Integrating Email Service

1. **Install SendGrid (example)**
```bash
npm install @sendgrid/mail
```

2. **Update AuthService**
```dart
// Replace console log with API call
static Future<void> sendVerificationCode(String email) async {
  final code = _generateVerificationCode();
  
  // Call Cloud Function
  final callable = FirebaseFunctions.instance.httpsCallable('sendVerificationEmail');
  await callable.call({
    'email': email,
    'code': code,
  });
  
  // Store code in Firestore with TTL
  await FirebaseFirestore.instance
      .collection('verification_codes')
      .doc(email.toLowerCase())
      .set({
        'code': code,
        'expiresAt': DateTime.now().add(Duration(minutes: 10)),
      });
}
```

3. **Update Firestore Rules**
   - See example above

4. **Deploy Cloud Function**
```bash
firebase deploy --only functions:sendVerificationEmail
```

## Support

For issues or questions:
- Check console logs for verification codes
- Verify Firebase Auth is enabled
- Check Firestore permissions
- Review error messages in SnackBars

## Security Considerations

⚠️ **Important for Production:**
- Never expose verification codes in logs
- Implement rate limiting (max 3 codes per hour)
- Add CAPTCHA to prevent bots
- Monitor failed login attempts
- Use HTTPS only
- Implement email verification timeout
- Add account lockout after failed attempts
- Store passwords securely (Firebase handles this)
- Audit user activity logs
