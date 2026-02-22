import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // Define shared constants
  static const primaryColor = Color(0xFF6366F1);
  static const secondaryColor = Color(0xFFEC4899);

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Color(0xFF1E293B),
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    inputDecorationTheme: _inputTheme(const Color(0xFF1E293B), Colors.white10),
  );

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
    inputDecorationTheme: _inputTheme(Colors.transparent, Colors.black12),
  );

  InputDecorationTheme _inputTheme(Color? fill, Color border) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        // border: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(12),
        //   borderSide: BorderSide.none,
        // ),
        // enabledBorder: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(12),
        //   borderSide: BorderSide(color: border),
        // ),
      );
}
