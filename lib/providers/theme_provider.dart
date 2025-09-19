import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false; // Default to light mode

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Theme data for light mode
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: const Color(0xFF5E4FCF),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: GoogleFonts.inter().fontFamily,
    // AppBarTheme set below with GoogleFonts
    primaryTextTheme: GoogleFonts.interTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        textStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      toolbarTextStyle: GoogleFonts.inter(
        textStyle: const TextStyle(color: Colors.black),
      ),
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      bodyLarge: const TextStyle(color: Colors.black),
      bodyMedium: const TextStyle(color: Colors.black87),
      titleLarge: const TextStyle(fontWeight: FontWeight.w700),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5E4FCF),
      brightness: Brightness.light,
    ),
  );

  // Theme data for dark mode
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: const Color(0xFF5E4FCF),
    scaffoldBackgroundColor: const Color(0xFF121316),
    fontFamily: GoogleFonts.inter().fontFamily,
    // AppBarTheme set below with GoogleFonts
    primaryTextTheme: GoogleFonts.interTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        textStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      toolbarTextStyle: GoogleFonts.inter(
        textStyle: const TextStyle(color: Colors.white),
      ),
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      bodyLarge: const TextStyle(color: Colors.white),
      bodyMedium: const TextStyle(color: Colors.white70),
      titleLarge: const TextStyle(color: Colors.white),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5E4FCF),
      brightness: Brightness.dark,
    ),
  );

  // Get current theme
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  // Toggle theme
  void toggleTheme() {
    // Force light mode only. Ignore toggle requests to enable dark mode.
    _isDarkMode = false;
    _saveThemeToPrefs();
    notifyListeners();
  }

  // Set theme directly
  void setTheme(bool isDark) {
    // Always enforce light mode regardless of request
    _isDarkMode = false;
    _saveThemeToPrefs();
    notifyListeners();
  }

  // Load theme preference from SharedPreferences
  void _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Always enforce light mode regardless of any previously saved preference
    _isDarkMode = false;
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Save theme preference to SharedPreferences
  void _saveThemeToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }
}
