# Authentication Flow Documentation

## Overview
The NDC95 app now has a comprehensive authentication system with multiple sign-in and sign-up methods.

## Authentication Screens

### 1. Sign In Screen (First Screen)
**File:** `lib/screens/signin_screen.dart`

This is the first screen users see after app loads. It provides email-based sign-in.

**Features:**
- Email input field with validation
- Checks if email exists in the database
- Sends verification code to registered email
- Links to Sign Up screen at the bottom
- Clean UI with gradient background

**User Flow:**
1. User enters their email
2. System checks if email exists
3. If exists: Sends 6-digit verification code
4. User verifies code
5. User enters password (if set) or signs in with Google credentials
6. Redirected to Home screen

**Error Handling:**
- Shows message if email not found: "No account found with this email. Please sign up first."
- Validates email format

---

### 2. Sign Up Screen
**File:** `lib/screens/signup_screen.dart`

This screen provides three different sign-up methods.

**Features:**
- **Sign Up with Google:** White button with Google icon, initiates Google OAuth flow
- **Sign Up with Email:** Blue outlined button, navigates to email registration
- **Sign In with Student ID:** Green outlined button, for existing users with Student IDs
- Link back to Sign In screen at bottom

**Sign-Up Options:**

#### A. Google Sign-Up
1. User clicks "Sign Up with Google"
2. Google authentication dialog opens
3. User selects Google account
4. System creates user profile in Firestore
5. Redirected to Home screen

#### B. Email Sign-Up
1. User clicks "Sign Up with Email"
2. Navigates to `EmailSignupScreen`
3. User enters email, name, phone, and optionally Student ID
4. Verification code sent to email
5. User verifies code
6. User sets password
7. Account created and redirected to Home

#### C. Student ID Sign-In
1. User clicks "Sign In with Student ID"
2. Navigates to `StudentIdSignInScreen`
3. Special flow for existing users (see below)

---

### 3. Student ID Sign-In Screen
**File:** `lib/screens/student_id_signin_screen.dart`

This screen allows users to sign in using their Student ID. It's designed for users who already have an account but want to add or verify their Student ID.

**Features:**
- Student ID input field
- Looks up existing accounts by Student ID
- Shows masked email for security (e.g., "na****@gmail.com")
- Sends verification code to full email
- Updates Student ID field after successful verification

**Security Features:**
- Email masking: Shows only first 2 characters and domain
- Verification required before any account access
- Prevents unauthorized Student ID changes

**User Flow:**
1. User enters Student ID (e.g., "95301023")
2. System queries Firestore for matching Student ID
3. **If found:**
   - Shows masked email: "Account found: na****@gmail.com"
   - Dialog asks: "Send verification code?"
   - User confirms
   - Code sent to full email address
   - User enters 6-digit code
   - After verification: System updates Student ID field (if needed)
   - User proceeds to sign in (password or Google)
4. **If not found:**
   - Shows message: "Student ID not found. Please sign up first or contact admin."
   - Suggests signing up via other methods

**Important:**
- This method is for existing users who want to associate or verify their Student ID
- After successful verification, the `studentId` field in Firestore is updated
- Ensures only the account owner can link a Student ID

**Help Information:**
The screen includes two info boxes:
1. **How it works:** Step-by-step guide
2. **Don't have a Student ID?:** Guidance for new members

---

## Email Verification Flow

**File:** `lib/screens/email_verification_screen.dart`

All authentication methods (except Google) use email verification for security.

**Features:**
- 6-digit code input (auto-submits when complete)
- 60-second countdown before resend
- Handles both new and existing users
- Special handling for Student ID sign-ins

**Enhanced for Student ID:**
- Accepts optional `studentId` parameter
- After successful verification, updates user's `studentId` field in Firestore
- Non-blocking: If Student ID update fails, verification still succeeds

**Code:**
```dart
EmailVerificationScreen(
  email: email,
  isExistingUser: true,
  studentId: studentId, // Optional parameter
)
```

---

## Database Structure

### User Document (Firestore)
```json
{
  "uid": "firebase_auth_uid",
  "email": "user@example.com",
  "name": "John Doe",
  "phone": "+1234567890",
  "studentId": "95301023", // Optional, can be added later
  "role": "member", // member, groupAdmin, admin, superAdmin
  "signUpMethod": "email", // email, google, studentId
  "createdAt": "2024-01-15T10:30:00Z",
  "hasPassword": true // true for email sign-ups
}
```

**Key Fields:**
- `email`: Unique, required
- `studentId`: Optional, unique if provided
- Both fields are validated for uniqueness during registration

---

## Routing and Navigation

### main.dart Changes
**File:** `lib/main.dart`

**Old Flow:**
```dart
AuthWrapper → LoginScreen (Google + Email button)
```

**New Flow:**
```dart
AuthWrapper → SignInScreen (Email sign-in) → SignUpScreen (3 options)
```

**Changes Made:**
1. Removed old `LoginScreen` class (200+ lines)
2. Changed `AuthWrapper` to return `SignInScreen`
3. Updated import from `email_signup_screen.dart` to `signin_screen.dart`

---

## Authentication Service Methods

### AuthService (lib/services/auth_service.dart)

**Key Methods:**
- `checkEmailExists(String email)` - Returns true if email is registered
- `sendVerificationCode(String email)` - Sends 6-digit code via email/Firestore
- `verifyCode(String email, String code)` - Validates verification code
- `signInExistingUser(String email)` - Checks password requirements
- `signInWithPassword(String email, String password)` - Signs in with email/password

**FirebaseService (lib/services/firebase_service.dart):**
- `signInWithGoogle()` - Google OAuth flow
- Firestore queries for Student ID lookup

---

## Security Features

### 1. Email Masking
**Location:** `student_id_signin_screen.dart`

Shows first 2 characters and full domain:
```dart
"nayeem.ahmad@gmail.com" → "na****@gmail.com"
"a@example.org" → "a***@example.org"
```

### 2. Verification Required
- All email-based flows require 6-digit code verification
- Codes expire after 10 minutes
- Rate limiting via 60-second cooldown

### 3. Unique Constraints
- Email must be unique across all users
- Student ID must be unique if provided
- Validated at both form level and database level

### 4. Student ID Protection
- Only account owner can link Student ID (via email verification)
- Cannot override existing Student ID without verification
- Masked email prevents email harvesting

---

## Error Handling

### Common Errors and Messages

**Sign In Screen:**
- Invalid email format: "Please enter a valid email"
- Email not found: "No account found with this email. Please sign up first."

**Student ID Sign-In:**
- Empty Student ID: "Please enter your Student ID"
- Not found: "Student ID not found. Please sign up first or contact admin."
- No associated email: "No email associated with this Student ID. Please contact admin."

**Email Verification:**
- Incomplete code: "Please enter the complete 6-digit code"
- Invalid/expired code: "Invalid or expired code. Please try again."
- Google account: "This account uses Google Sign-In. Please use Google to sign in."
- Needs password: Shows password dialog

---

## Testing Checklist

### Sign In Flow
- [ ] Email validation works (format check)
- [ ] Correct error when email doesn't exist
- [ ] Verification code sent successfully
- [ ] Code verification works
- [ ] Password entry works for email users
- [ ] Redirects to home after successful sign-in

### Sign Up Flow
- [ ] All three buttons visible and styled correctly
- [ ] Google sign-up works (OAuth flow)
- [ ] Email sign-up navigates correctly
- [ ] Student ID button navigates correctly
- [ ] "Already have account" link works

### Student ID Flow
- [ ] Student ID input accepts text
- [ ] Valid Student ID lookup works
- [ ] Masked email displays correctly
- [ ] Verification code dialog appears
- [ ] Code sent to correct email
- [ ] Student ID field updated after verification
- [ ] Invalid Student ID shows proper error

### Edge Cases
- [ ] Network errors handled gracefully
- [ ] Duplicate emails prevented
- [ ] Duplicate Student IDs prevented
- [ ] Empty Student ID allowed (optional field)
- [ ] Navigation back button works properly
- [ ] Loading states shown during async operations

---

## UI/UX Improvements

### Design Consistency
- Gradient backgrounds (blue → purple)
- Consistent button styling:
  - Google: White with grey border
  - Email: Blue outline
  - Student ID: Green outline
- Card-based forms with elevation
- Proper spacing and padding

### Accessibility
- Clear labels on all inputs
- Error messages in red
- Success messages in green
- Info messages in amber/orange
- Loading indicators during operations

### User Guidance
- Placeholder text in fields
- Info boxes explaining processes
- Help text for Student ID flow
- Privacy policy notices

---

## Future Enhancements

### Potential Improvements
1. **Password Reset:** Add "Forgot Password?" link on Sign In screen
2. **Social Sign-In:** Add Facebook, Apple, or other providers
3. **Biometric Auth:** Fingerprint/Face ID for returning users
4. **Remember Me:** Option to stay signed in
5. **Profile Completion:** Prompt for Student ID if not provided during sign-up
6. **Admin Dashboard:** View all authentication methods by user

### Security Enhancements
1. **Two-Factor Authentication:** Optional 2FA for admin users
2. **Login History:** Track sign-in attempts and devices
3. **Session Management:** Force re-authentication after period
4. **Account Recovery:** More robust recovery options

---

## Related Files

### Screens
- `lib/screens/signin_screen.dart` - Sign in (email)
- `lib/screens/signup_screen.dart` - Sign up (3 options)
- `lib/screens/student_id_signin_screen.dart` - Student ID authentication
- `lib/screens/email_verification_screen.dart` - 6-digit code verification
- `lib/screens/email_signup_screen.dart` - Email registration form
- `lib/screens/set_password_screen.dart` - Password setup for new users

### Services
- `lib/services/auth_service.dart` - Authentication logic
- `lib/services/firebase_service.dart` - Firebase operations
- `lib/services/role_service.dart` - Role-based permissions

### Main
- `lib/main.dart` - App entry point and routing

---

## Changelog

### Version 2.0 - Authentication Restructure
**Date:** 2024

**Changes:**
1. ✅ Separated Sign In and Sign Up into different screens
2. ✅ Added Student ID authentication method
3. ✅ Implemented email masking for security
4. ✅ Updated Student ID field after verification
5. ✅ Removed old LoginScreen
6. ✅ Updated main.dart routing
7. ✅ Enhanced EmailVerificationScreen with Student ID support
8. ✅ Improved UI consistency across all auth screens

**Previous Versions:**
- v1.3: Student ID uniqueness validation
- v1.2: Email authentication with verification
- v1.1: Role-based permissions system
- v1.0: Initial Google authentication

---

## Contact & Support

For issues or questions about the authentication system:
- Check existing documentation in the repository
- Review error messages carefully
- Contact the development team
- Report bugs via GitHub issues
