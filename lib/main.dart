import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart'; // Add this line
import 'package:flutter/material.dart';
import 'package:inkflow_mad_sem_project/pages/authors/authors_page.dart';
import 'package:inkflow_mad_sem_project/pages/books/book_detail.dart';
import 'package:inkflow_mad_sem_project/pages/books/books_page.dart';
import 'package:inkflow_mad_sem_project/pages/home/home_screen.dart';
import 'package:inkflow_mad_sem_project/pages/library/library_page.dart';
import 'firebase_options.dart';
import 'pages/login_signup/login_screen.dart';
import 'pages/login_signup/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully!");
  } catch (e) {
    print("Firebase initialization failed: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InkFlow',
      // Remove initialRoute and use home instead
      home: AuthWrapper(),
      routes: {
        '/library': (context) => Library(),
        '/all_books': (context) => Books(),
        '/all_authors': (context) => Authors(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
      },
      // Add this to handle routes that need parameters
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/book_detail':
            final book = settings.arguments as Map<String, String>? ?? {};
            return MaterialPageRoute(
              builder: (context) => BookDetail(book: book),
            );
          default:
            return null;
        }
      },
    );
  }
}

// New AuthWrapper widget to handle authentication state
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, show home screen
        if (snapshot.hasData && snapshot.data != null) {
          print("User is logged in: ${snapshot.data!.email}");
          return HomeScreen();
        }

        // If no user is logged in, show login screen
        print("No user logged in, showing login screen");
        return LoginScreen();
      },
    );
  }
}