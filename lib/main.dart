import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:inkflow_mad_sem_project/pages/authors/authors_page.dart';
import 'package:inkflow_mad_sem_project/pages/books/book_detail.dart';
import 'package:inkflow_mad_sem_project/pages/books/books_page.dart';
import 'package:inkflow_mad_sem_project/pages/home/home_screen.dart';
import 'package:inkflow_mad_sem_project/pages/library/library_page.dart';
import 'firebase_options.dart';
import 'pages/login_signup/login_screen.dart';
import 'pages/login_signup/signup_screen.dart';
import 'package:standard_searchbar/old/standard_searchbar.dart';
import 'package:google_fonts/google_fonts.dart';

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
      initialRoute: '/login',
      routes: {
        '/': (context) => HomeScreen(),
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