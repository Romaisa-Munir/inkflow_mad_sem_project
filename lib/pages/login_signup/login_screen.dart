import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
// Import Firebase Auth and Realtime Database packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class LoginScreen extends StatelessWidget {
  // Text controllers for getting user input
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 🔐 Firebase Authentication: login function
  Future<void> _login(BuildContext context) async {
    // Get trimmed input from controllers
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Check if either field is empty
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    try {
      // 👉 Attempt to sign in using Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Get the user object from the result
      final User? user = userCredential.user;

      if (user != null) {
        // ✅ Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Logged in as ${user.email}"),
            backgroundColor: Colors.green,
          ),
        );

        // 🗃️ Optional: Save login time in Realtime Database
        final db = FirebaseDatabase.instance.ref();
        await db.child("users/${user.uid}/lastLogin").set(DateTime.now().toIso8601String());

        // 🚀 Navigate to the main/home screen
        Navigator.pushReplacementNamed(context, '/'); // Adjust route as needed
      }
    } catch (e) {
      // ❌ Handle errors such as wrong password, user not found, etc.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Login failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 Colors pulled from your theme
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final inversePrimaryColor = Theme.of(context).colorScheme.inversePrimary;

    // 🎯 Reusable input decoration for email & password
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
        title: Text("Login"),
        backgroundColor: inversePrimaryColor,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 📧 Email input field
            TextField(
              controller: emailController,
              decoration: inputDecoration('Email'),
            ),
            SizedBox(height: 15),

            // 🔐 Password input field
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: inputDecoration('Password'),
            ),
            SizedBox(height: 30),

            // 🔘 Login button (calls _login)
            ElevatedButton(
              onPressed: () => _login(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text("Login"),
            ),
            SizedBox(height: 15),

            // 🔁 Link to Sign Up page
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup'); // Navigate to signup screen
              },
              style: TextButton.styleFrom(foregroundColor: primaryColor),
              child: Text("Don't have an account? Sign up"),
            )
          ],
        ),
      ),
    );
  }
}
