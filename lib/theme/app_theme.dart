import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      primaryColor: Colors.deepPurple,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        primary: Colors.deepPurple,
        secondary: Colors.deepPurpleAccent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.deepPurple.shade100,
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
    );
  }
}