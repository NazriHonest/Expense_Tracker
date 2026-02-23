import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/finance_colors.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  static const _primary = Color(0xFF6366F1);
  static const _secondary = Color(0xFFEC4899);

  // ================= DARK =================

  ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: _primary,
      secondary: _secondary,
      surface: Color(0xFF1E293B),
      error: Color(0xFFFB7185),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Color(0xFF0F172A),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: _inputTheme(
        const Color(0xFF1E293B),
        Colors.white12,
      ),

      extensions: const [
        FinanceColors(
          income: Color(0xFF4ADE80),
          expense: Color(0xFFFB7185),
          savings: Color(0xFF2DD4BF),
          budget: Color(0xFF818CF8),
          recurring: Color(0xFFFBBF24),
          debt: Color(0xFFF43F5E),
          wallet: Color(0xFFA78BFA),
          health: Color(0xFF22D3EE),
        ),
      ],
    );
  }

  // ================= LIGHT =================

  ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: _primary,
      secondary: _secondary,
      surface: Colors.white,
      error: Color(0xFFDC2626),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),

      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: _inputTheme(
        const Color(0xFFF1F5F9),
        Colors.black12,
      ),

      extensions: const [
        FinanceColors(
          income: Color(0xFF16A34A),
          expense: Color(0xFFDC2626),
          savings: Color(0xFF0D9488),
          budget: Color(0xFF4F46E5),
          recurring: Color(0xFFF59E0B),
          debt: Color(0xFFB91C1C),
          wallet: Color(0xFF7C3AED),
          health: Color(0xFF06B6D4),
        ),
      ],
    );
  }

  // ================= INPUT =================

  InputDecorationTheme _inputTheme(Color fill, Color border) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primary, width: 1.5),
      ),
    );
  }
}
