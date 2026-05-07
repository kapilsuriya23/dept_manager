import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Solar Green Palette (from UI reference) ──────────────
  static const primaryGreen = Color(0xFF7ED321); // lime accent
  static const lightGreen = Color(0xFFAAED4A); // lighter lime
  static const darkGreen = Color(0xFF3B6D11); // deep forest
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const bgPage = Color(0xFFF0F7E8); // soft green tint
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1C2B1A); // near-black charcoal
  static const textSecondary = Color(0xFF5A7050); // muted green-gray
  static const textHint = Color(0xFF8FA885);
  static const borderColor = Color(0xFFD4E8C2);
  static const dangerColor = Color(0xFFE53935);
  static const successColor = Color(0xFF3B6D11);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bgPage,
        colorScheme: const ColorScheme.light(
          primary: primaryGreen,
          secondary: lightGreen,
          surface: surfaceWhite,
          error: dangerColor,
          onPrimary: Colors.white,
          onSurface: textPrimary,
        ),
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          bodyMedium: GoogleFonts.poppins(color: textPrimary),
          bodySmall: GoogleFonts.poppins(color: textSecondary),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceWhite,
          elevation: 0,
          centerTitle: false,
          foregroundColor: textPrimary,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borderColor, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5FAF0),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textHint),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: dangerColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: dangerColor, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        dividerTheme: const DividerThemeData(color: borderColor, space: 1),
      );
}
