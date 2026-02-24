import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Authentication Service
/// Handles user authentication (register, login, logout)
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register new user with email and password
  Future<User?> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth exceptions with user-friendly messages
      throw Exception(_handleAuthException(e));
    } catch (e) {
      // Handle platform channel or other unexpected errors
      final errorString = e.toString().toLowerCase();

      // Check for the specific type casting error
      if (errorString.contains('pigeonuserdetails') ||
          errorString.contains('list<object?>') ||
          errorString.contains('type cast')) {
        // This is likely a Firebase plugin compatibility issue
        // Try to get a better error message
        if (errorString.contains('email-already-in-use') ||
            errorString.contains('already exists')) {
          throw Exception('An account already exists for that email.');
        }
        throw Exception(
          'Registration failed. Please try again or contact support if the issue persists.',
        );
      }

      // Handle other errors
      if (errorString.contains('email-already-in-use') ||
          errorString.contains('already exists')) {
        throw Exception('An account already exists for that email.');
      } else if (errorString.contains('weak-password')) {
        throw Exception('The password provided is too weak.');
      } else if (errorString.contains('invalid-email')) {
        throw Exception('The email address is invalid.');
      }

      // Generic error fallback
      throw Exception(
        'Registration failed. Please check your connection and try again.',
      );
    }
  }

  /// Login user with email and password
  Future<User?> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Reauthenticate user with email and password
  Future<void> reauthenticateWithCredential(
    String email,
    String password,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user password
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
    String email,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      // Reauthenticate first
      await reauthenticateWithCredential(email, currentPassword);

      // Then update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Check if email already exists in Firebase Auth
  /// Note: This method can cause type casting issues, so we'll handle duplicates via exceptions
  /// Instead of pre-checking, we'll let Firebase throw 'email-already-in-use' exception
  Future<bool> emailAlreadyExists(String email) async {
    // Removed fetchSignInMethodsForEmail due to type casting issues
    // We'll handle duplicate emails via FirebaseAuthException in register method
    return false;
  }

  /// Sign in with Google (Android only)
  /// Always shows account picker by signing out first
  Future<User?> signInWithGoogle() async {
    try {
      // Sign out first to force account selection dialog every time
      // This ensures users can choose different accounts on each sign-in
      await _googleSignIn
          .signOut()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⚠️ Google Sign-Out timeout (non-critical)');
            },
          )
          .catchError((e) {
            debugPrint('⚠️ Google Sign-Out error (non-critical): $e');
          });

      // Trigger the authentication flow (will show account picker)
      // Add timeout to prevent infinite hanging
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signIn()
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception('Google Sign-In timed out. Please try again.');
            },
          );

      if (googleUser == null) {
        // User canceled the sign-in
        throw Exception('Google Sign-In was canceled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      // Update Firebase user profile with Google account info if missing
      if (user != null) {
        bool needsUpdate = false;
        final updates = <String, dynamic>{};

        // Update display name if it's missing or different from Google account
        if (googleUser.displayName != null &&
            googleUser.displayName!.isNotEmpty) {
          if (user.displayName == null ||
              user.displayName != googleUser.displayName) {
            updates['displayName'] = googleUser.displayName;
            needsUpdate = true;
          }
        }

        // Update photo URL if it's missing or different from Google account
        if (googleUser.photoUrl != null && googleUser.photoUrl!.isNotEmpty) {
          if (user.photoURL == null || user.photoURL != googleUser.photoUrl) {
            updates['photoURL'] = googleUser.photoUrl;
            needsUpdate = true;
          }
        }

        // Apply updates if needed (with timeout to prevent hanging)
        if (needsUpdate && updates.isNotEmpty) {
          try {
            // Use timeout to prevent hanging indefinitely
            await Future.any([
              Future(() async {
                if (updates.containsKey('displayName')) {
                  await user.updateDisplayName(
                    updates['displayName'] as String?,
                  );
                }
                if (updates.containsKey('photoURL')) {
                  await user.updatePhotoURL(updates['photoURL'] as String?);
                }
                // Reload user to get updated info
                await user.reload();
              }),
              Future.delayed(const Duration(seconds: 5), () {
                throw Exception('Profile update timed out');
              }),
            ]).catchError((e) {
              // Log but don't fail - user can still sign in
              debugPrint('⚠️ Could not update user profile (non-blocking): $e');
            });
          } catch (e) {
            // Log but don't fail - user can still sign in
            debugPrint('⚠️ Could not update user profile: $e');
          }
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Handle Google Sign-In specific errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('canceled') ||
          errorString.contains('cancelled')) {
        throw Exception('Google Sign-In was canceled');
      } else if (errorString.contains('network')) {
        throw Exception(
          'Network error. Please check your internet connection.',
        );
      } else {
        throw Exception('Google Sign-In failed: ${e.toString()}');
      }
    }
  }

  /// Logout current user
  Future<void> logout() async {
    // Sign out from Google as well
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
