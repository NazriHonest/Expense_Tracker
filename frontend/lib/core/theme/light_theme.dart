import 'package:flutter/material.dart';
import 'finance_colors.dart';

class LightTheme {
  static ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF1E3A8A),
      onPrimary: Colors.white,
      secondary: Color(0xFF10B981),
      onSecondary: Colors.white,
      error: Color(0xFFDC2626),
      onError: Colors.white,
      // background: Color(0xFFF8FAFC), Deprecated
      // onBackground: Color(0xFF0F172A), Deprecated
      surface: Color(0xFFF8FAFC),
      onSurface: Color(0xFF0F172A),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
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
