import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
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