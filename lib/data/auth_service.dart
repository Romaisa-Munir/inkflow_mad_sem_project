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
    print("🚀 Starting signup process for: $email");

    try {
      print("📝 Creating user with Firebase Auth...");
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim()
      );

      User? user = result.user;
      print("✅ User created in Firebase Auth: ${user?.uid}");

      // Store user data in Realtime Database
      if (user != null) {
        try {
          print("💾 Saving user data to Realtime Database...");

          Map<String, dynamic> userData = {
            'email': email.trim(),
            'createdAt': DateTime.now().toIso8601String(),
            'lastLogin': DateTime.now().toIso8601String(),
          };

          print("📋 User data to save: $userData");

          await _database.child('users').child(user.uid).set(userData);

          print("✅ User data saved to database successfully!");
        } catch (dbError) {
          print("❌ Database save error: $dbError");
          print("❌ Database error type: ${dbError.runtimeType}");
          // Continue with signup even if database save fails
        }
      } else {
        print("❌ User object is null after creation");
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Auth error: ${e.code} - ${e.message}");
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
      print("❌ General signup error: $e");
      print("❌ Error type: ${e.runtimeType}");
      return 'An unexpected error occurred';
    }
  }

  // Sign In Function
  Future<String?> signIn(String email, String password) async {
    print("🚀 Starting login process for: $email");

    try {
      print("🔐 Checking credentials with Firebase Auth...");
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim()
      );

      User? user = result.user;
      print("✅ User logged in successfully: ${user?.uid}");

      // Update last login in database
      if (user != null) {
        try {
          print("💾 Updating last login in database...");

          // Check if user record exists first
          DataSnapshot snapshot = await _database.child('users').child(user.uid).get();

          if (snapshot.exists) {
            print("📄 User record exists, updating lastLogin...");
            await _database.child('users').child(user.uid).update({
              'lastLogin': DateTime.now().toIso8601String(),
            });
            print("✅ Last login updated successfully!");
          } else {
            print("⚠️ User record doesn't exist, creating new one...");
            await _database.child('users').child(user.uid).set({
              'email': email.trim(),
              'createdAt': DateTime.now().toIso8601String(),
              'lastLogin': DateTime.now().toIso8601String(),
            });
            print("✅ User record created successfully!");
          }
        } catch (dbError) {
          print("❌ Database update error: $dbError");
          print("❌ Database error type: ${dbError.runtimeType}");
          // Continue with login even if database update fails
        }
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Auth login error: ${e.code} - ${e.message}");
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
      print('❌ General login error: $e');
      print("❌ Error type: ${e.runtimeType}");
      return 'An unexpected error occurred';
    }
  }

  // Sign Out Function
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print("✅ User signed out successfully");
    } catch (e) {
      print('❌ Sign out error: $e');
    }
  }

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Get user email
  String? get userEmail => currentUser?.email;

  // Get user ID
  String? get userId => currentUser?.uid;
}