import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Clear user data from local storage
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('User data cleared from local storage');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  // Sign Up with Email and Password
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('User signed up successfully: ${userCredential.user?.email}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected error: $e');
      return null;
    }
  }

  // Sign In with Email and Password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('User signed in successfully: ${userCredential.user?.email}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.code} - ${e.message}');
      rethrow; // Rethrow the exception so the UI can handle it
    } catch (e) {
      debugPrint('Unexpected error: $e');
      rethrow; // Rethrow the exception so the UI can handle it
    }
  }

  // Google Sign-In (mobile & web)
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: use signInWithPopup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        debugPrint('Web Google sign-in successful: ${userCredential.user?.email}');
        return userCredential.user;
      } else {
        // Mobile: use GoogleSignIn
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          debugPrint('Google sign-in cancelled by user');
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        debugPrint('Mobile Google sign-in successful: ${userCredential.user?.email}');
        return userCredential.user;
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      
      // Clear user data from local storage
      await _clearUserData();
      
      debugPrint('User signed out successfully.');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // Get Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
//     }
//   }

//   // Get Current User
//   User? getCurrentUser() {
//     return _auth.currentUser;
//   }

//   // Reset Password
//   Future<void> resetPassword(String email) async {
//     try {
//       await _auth.sendPasswordResetEmail(email: email);
//       log('Password reset email sent to $email');
//     } catch (e) {
//       log('Error sending password reset email: $e', error: e);
//     }
//   }
// }
