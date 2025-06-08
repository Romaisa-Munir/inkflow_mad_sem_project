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


//https://pub.dev/packages/standard_searchbar
//https://pub.dev/packages/google_fonts
import 'package:standard_searchbar/old/standard_searchbar.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uncomment this now that firebase_options.dart exists
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
      // Routes
      initialRoute: '/login',
      routes: {
        // When navigating to the "/" route, build the HomeScreen widget.
        '/': (context) => HomeScreen(),
        // When navigating to the "/library" route, build the Library widget.
        '/library': (context) => Library(),
        '/book_detail': (context) => BookDetail(book: {},),
        '/all_books': (context) => Books(),
        '/all_authors': (context)=> Authors(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
      },
    );
  }
}
