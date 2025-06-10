import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SignupScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 🔐 Firebase signup function
  Future<void> _signUp(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Basic form validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    try {
      // 🧾 Create user with Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;

      if (user != null) {
        // 🗃️ Store user data in Firebase Realtime Database
        final db = FirebaseDatabase.instance.ref();
        await db.child("users/${user.uid}").set({
          "email": user.email,
          "createdAt": DateTime.now().toIso8601String(),
        });

        // ✅ Success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Account created for ${user.email}"),
            backgroundColor: Colors.green,
          ),
        );

        // ➡️ Redirect to login
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      // ❌ Handle errors like weak password, duplicate email, etc.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Signup failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 App colors
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final inversePrimaryColor = Theme.of(context).colorScheme.inversePrimary;

    InputDecoration inputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: secondaryColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up"),
        backgroundColor: inversePrimaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 📧 Email input
            TextField(
              controller: emailController,
              decoration: inputDecoration('Email'),
            ),
            SizedBox(height: 15),

            // 🔐 Password input
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: inputDecoration('Password'),
            ),
            SizedBox(height: 30),

            // 🔘 Sign Up button
            ElevatedButton(
              onPressed: () => _signUp(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text("Sign Up"),
            ),

            // 🔁 Already have an account
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
              child: Text("Already have an account? Login"),
            )
          ],
        ),
      ),
    );
  }
}

