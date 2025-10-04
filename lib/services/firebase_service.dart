import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'dart:typed_data';

/// Firebase service to handle authentication, database, and messaging
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get auth instance
  static FirebaseAuth get auth => _auth;

  // Get firestore instance
  static FirebaseFirestore get firestore => _firestore;

  // Get messaging instance
  static FirebaseMessaging get messaging => _messaging;

  /// Sign in with email and password
  static Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign up with email and password
  static Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      print('🔵 Starting Google Sign-In...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        print('⚠️ User canceled Google Sign-In');
        return null;
      }

      print('✅ Google account selected: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔵 Signing in to Firebase...');
      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      print('✅ Firebase sign-in successful: ${userCredential.user?.email}');

      // Create user profile if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        print('🔵 Creating user profile in Firestore...');
        try {
          await createUserProfile(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            displayName: userCredential.user!.displayName,
            photoUrl: userCredential.user!.photoURL,
          );
          print('✅ User profile created successfully');
        } catch (firestoreError) {
          print('⚠️ Firestore error (non-fatal): $firestoreError');
          print(
            'Note: You may need to enable Firestore API in Firebase Console',
          );
          // Don't throw - allow sign-in to proceed even if Firestore fails
        }
      } else {
        print('ℹ️ Existing user signed in');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Google Sign-In Error: $e');
      throw 'Failed to sign in with Google: ${e.toString()}';
    }
  }

  /// Send phone verification code
  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  /// Verify phone number with SMS code
  static Future<UserCredential> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Request notification permissions
  static Future<void> requestNotificationPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  /// Get FCM token for push notifications
  static Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Listen to FCM token refresh
  static Stream<String> onTokenRefresh() {
    return _messaging.onTokenRefresh;
  }

  /// Create user profile in Firestore
  static Future<void> createUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    // Check if email is the superadmin email
    final role = email.toLowerCase() == 'nayeem.ahmad@gmail.com'
        ? 'superadmin'
        : 'member';

    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName ?? '',
      'phoneNumber': phoneNumber ?? '',
      'photoUrl': photoUrl ?? '',
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get user profile from Firestore
  static Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    required String uid,
    Map<String, dynamic>? data,
  }) async {
    if (data != null) {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(data);
    }
  }

  /// Upload profile picture to Firebase Storage
  static Future<String?> uploadProfilePicture({
    required String uid,
    required File imageFile,
  }) async {
    try {
      // Create a reference to the file location
      final storageRef = _storage.ref().child('profile_pictures/$uid.jpg');

      // Upload the file
      final uploadTask = await storageRef.putFile(imageFile);

      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update user profile with new photo URL
      await updateUserProfile(uid: uid, data: {'photoUrl': downloadUrl});

      // Update Firebase Auth profile
      await _auth.currentUser?.updatePhotoURL(downloadUrl);

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Upload a notice banner image to Firebase Storage
  static Future<String?> uploadNoticeBanner({
    required Uint8List data,
    required String fileName,
    String? contentType,
  }) async {
    try {
      debugPrint('🔵 Starting Firebase Storage upload for: $fileName');
      final normalizedName = fileName.toLowerCase().replaceAll(' ', '_');
      final reference = _storage.ref().child('notices/banners/$normalizedName');
      final metadata = SettableMetadata(contentType: contentType);
      debugPrint('🔵 Uploading ${data.length} bytes to: notices/banners/$normalizedName');
      final task = await reference.putData(data, metadata);
      final downloadUrl = await task.ref.getDownloadURL();
      debugPrint('✅ Firebase Storage upload complete. URL: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading notice banner: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Upload a gallery cover image to Firebase Storage
  static Future<String?> uploadGalleryCover(
    String galleryId,
    String fileName,
    List<int> fileBytes,
  ) async {
    try {
      final normalizedName = fileName.toLowerCase().replaceAll(' ', '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final reference = _storage.ref().child('galleries/$galleryId/cover/${timestamp}_$normalizedName');
      
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
      );
      
      final task = await reference.putData(Uint8List.fromList(fileBytes), metadata);
      final downloadUrl = await task.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading gallery cover: $e');
      return null;
    }
  }

  /// Upload gallery media (photo/video) to Firebase Storage
  static Future<String?> uploadGalleryMedia(
    String galleryId,
    String fileName,
    List<int> fileBytes,
    dynamic mediaType, // MediaType enum
  ) async {
    try {
      final normalizedName = fileName.toLowerCase().replaceAll(' ', '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final typeString = mediaType.toString().split('.').last; // 'image' or 'video'
      final reference = _storage.ref().child('galleries/$galleryId/media/${timestamp}_$normalizedName');
      
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: {'type': typeString},
      );
      
      final task = await reference.putData(Uint8List.fromList(fileBytes), metadata);
      final downloadUrl = await task.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading gallery media: $e');
      return null;
    }
  }

  /// Helper method to determine content type from file extension
  static String _getContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }

  /// Handle authentication exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
