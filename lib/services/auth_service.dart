import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// Authentication service for email verification and signup
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Store verification codes temporarily (in production, use Firebase Functions or backend)
  static final Map<String, String> _verificationCodes = {};
  static final Map<String, DateTime> _codeExpiry = {};

  /// Check if email exists in the database
  static Future<bool> checkEmailExists(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  /// Generate and send verification code
  static Future<void> sendVerificationCode(String email) async {
    // Generate 6-digit code
    final code = _generateVerificationCode();
    
    // Store code and expiry (10 minutes)
    _verificationCodes[email.toLowerCase()] = code;
    _codeExpiry[email.toLowerCase()] = DateTime.now().add(const Duration(minutes: 10));
    
    // In production, send email via Firebase Functions or backend
    // For now, just print it (you can implement email sending later)
    print('📧 Verification code for $email: $code');
    print('⏰ Code expires in 10 minutes');
    
    // TODO: Integrate with email service (SendGrid, AWS SES, etc.)
    // For development, the code is logged to console
  }

  /// Verify the code entered by user
  static Future<bool> verifyCode(String email, String code) async {
    final storedCode = _verificationCodes[email.toLowerCase()];
    final expiry = _codeExpiry[email.toLowerCase()];
    
    if (storedCode == null || expiry == null) {
      throw 'No verification code found. Please request a new code.';
    }
    
    if (DateTime.now().isAfter(expiry)) {
      _verificationCodes.remove(email.toLowerCase());
      _codeExpiry.remove(email.toLowerCase());
      throw 'Verification code has expired. Please request a new code.';
    }
    
    if (storedCode != code) {
      throw 'Invalid verification code. Please try again.';
    }
    
    // Code is valid
    _verificationCodes.remove(email.toLowerCase());
    _codeExpiry.remove(email.toLowerCase());
    return true;
  }

  /// Sign in existing user after verification
  static Future<UserCredential> signInExistingUser(String email) async {
    try {
      // Get user document to find their auth method
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      
      if (userQuery.docs.isEmpty) {
        throw 'User not found';
      }
      
      final userData = userQuery.docs.first.data();
      final hasPassword = userData['hasPassword'] ?? false;
      
      if (!hasPassword) {
        // User signed up with Google, need to use Google Sign-In
        throw 'This email is registered with Google. Please use "Continue with Google" to sign in.';
      }
      
      // If user has password, they need to enter it
      // This will be handled in the verification screen
      throw 'Password required';
    } catch (e) {
      rethrow;
    }
  }

  /// Create new user account with password
  static Future<UserCredential> createUserWithPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Create Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
      }
      
      // Create user profile in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email.toLowerCase(),
        'displayName': displayName ?? '',
        'hasPassword': true,
        'authProvider': 'email',
        'photoUrl': '',
        'phoneNumber': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'This email is already registered. Please sign in instead.';
      } else if (e.code == 'weak-password') {
        throw 'Password is too weak. Please use at least 6 characters.';
      } else if (e.code == 'invalid-email') {
        throw 'Invalid email address.';
      }
      throw e.message ?? 'Failed to create account';
    }
  }

  /// Sign in with email and password
  static Future<UserCredential> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        throw 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        throw 'Invalid email address.';
      } else if (e.code == 'user-disabled') {
        throw 'This account has been disabled.';
      }
      throw e.message ?? 'Failed to sign in';
    }
  }

  /// Generate random 6-digit verification code
  static String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Resend verification code
  static Future<void> resendVerificationCode(String email) async {
    await sendVerificationCode(email);
  }

  /// Send password reset email (Firebase built-in)
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'No account found with this email.';
      }
      throw e.message ?? 'Failed to send reset email';
    }
  }
}
