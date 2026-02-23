import 'package:flutter/material.dart';
import 'finance_colors.dart';

class DarkTheme {
  static ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF3B82F6),
      onPrimary: Colors.white,
      secondary: Color(0xFF34D399),
      onSecondary: Colors.black,
      error: Color(0xFFFB7185),
      onError: Colors.black,
      surface: Color(0xFF1E293B),
      onSurface: Color(0xFFF1F5F9),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
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
