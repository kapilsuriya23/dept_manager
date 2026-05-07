import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF1A1F2E);
  static const accentColor = Color(0xFFFF6B35);
  static const surfaceColor = Color(0xFF242938);
  static const cardColor = Color(0xFF2D3348);
  static const successColor = Color(0xFF4CAF50);
  static const dangerColor = Color(0xFFE53935);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: primaryColor,
        colorScheme: const ColorScheme.dark(
          primary: accentColor,
          surface: surfaceColor,
          error: dangerColor,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          labelStyle: const TextStyle(color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: dangerColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: dangerColor, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
}
