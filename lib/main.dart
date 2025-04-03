import 'package:flutter/material.dart';
import 'package:standard_searchbar/old/standard_searchbar.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InkFlow',
      // App theme
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple,
          secondary: Colors.deepPurpleAccent,
        ),
        // NavBar theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.deepPurple.shade100,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.deepPurple.shade300,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
          // App font
          textTheme: GoogleFonts.cinzelTextTheme(),
      ),
      initialRoute: '/',
      routes: {
        // When navigating to the "/" route, build the HomeScreen widget.
        '/': (context) => HomeScreen(),
        // When navigating to the "/second" route, build the Library widget.
        '/library': (context) => Library(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:Text('Inkflow'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        // Search Bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: StandardSearchBar(
            width: double.infinity,
            horizontalPadding: 10,
          )
        ),
      ],
    ),
    // Bottom Nav Bar
    bottomNavigationBar: BottomNavigationBar(
        items: [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Create'),
      BottomNavigationBarItem(icon: Icon(Icons.my_library_books_rounded), label: 'Library'),
    ],
      currentIndex: 0, // HomeScreen Index
      onTap: (index) {
        // Library Index, tapping on lib icon takes to library screen
        if (index == 2) {
          Navigator.pushNamed(context, '/library');
        }
      },
    ),
    );
  }
}
class Library extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

    );
  }
}