import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up Function
  Future<String?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim()
      );

      User? user = result.user;

      // Store user data in Realtime Database
      if (user != null) {
        await _database.child('users').child(user.uid).set({
          'email': email.trim(),
          'createdAt': DateTime.now().toIso8601String(),
          'lastLogin': DateTime.now().toIso8601String(),
        });
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'weak-password':
          return 'Password is too weak';
        case 'email-already-in-use':
          return 'Email is already registered';
        case 'invalid-email':
          return 'Invalid email format';
        default:
          return e.message ?? 'Sign up failed';
      }
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Sign In Function
  Future<String?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim()
      );

      // Update last login in database
      User? user = result.user;
      if (user != null) {
        await _database.child('users').child(user.uid).update({
          'lastLogin': DateTime.now().toIso8601String(),
        });
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'invalid-email':
          return 'Invalid email format';
        case 'user-disabled':
          return 'This account has been disabled';
        default:
          return e.message ?? 'Login failed';
      }
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Sign Out Function
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Get user email
  String? get userEmail => currentUser?.email;

  // Get user ID
  String? get userId => currentUser?.uid;
}