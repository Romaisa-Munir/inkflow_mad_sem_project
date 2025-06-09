import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../data/auth_service.dart';

class LoginScreen extends StatelessWidget {
  final AuthService _authService = AuthService(); // Add this line
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Firebase test function
  void _testFirebase(BuildContext context) async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref().child('test');
      DataSnapshot snapshot = await ref.get();

      if (snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Firebase connected! Data: ${snapshot.value}"),
              backgroundColor: Colors.green,
            )
        );
        print("Firebase test successful: ${snapshot.value}");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("⚠️ Firebase connected but no data found"),
              backgroundColor: Colors.orange,
            )
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Firebase error: $e"),
            backgroundColor: Colors.red,
          )
      );
      print("Firebase error: $e");
    }
  }

  void _handleLogin(BuildContext context) async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    String? result = await _authService.signIn(email, password);
    if (result == null) {
      // Success - navigate to home
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Login successful!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/');
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ $result"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    // colors of app
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
        title: Text("Login"),
        backgroundColor: inversePrimaryColor,
        automaticallyImplyLeading: false,
        centerTitle: true, // To match your other AppBars
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: inputDecoration('Email'),
            ),
            SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: inputDecoration('Password'),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _handleLogin(context),
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
            // Add Firebase test button
            ElevatedButton(
              onPressed: () => _testFirebase(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text("Test Firebase"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup'); // Use named route
              },
              style: TextButton.styleFrom(
                foregroundColor: primaryColor, // Match text color to theme
              ),
              child: Text("Don't have an account? Sign up"),
            )
          ],
        ),
      ),
    );
  }
}