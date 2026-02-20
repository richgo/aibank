import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BankTheme {
  // Brand colors
  static const Color primaryGreen = Color(0xFF006B3D);    // Lloyds-inspired deep green
  static const Color accentCoral = Color(0xFFFF6B6B);     // Monzo-inspired coral
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color positive = Color(0xFF1B8A3A);        // positive balance
  static const Color negative = Color(0xFFD32F2F);        // negative balance

  // Design tokens
  static const double cardRadius = 24.0;
  static const double panelRadius = 16.0;
  static const double buttonRadius = 8.0;
  static const double elevationResting = 2.0;
  static const double elevationInteractive = 4.0;
  static const double elevationModal = 8.0;
  static const double spacingCompact = 12.0;
  static const double spacing = 16.0;
  static const double spacingSpacious = 24.0;

  // Gradient helper
  static LinearGradient cardGradient() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF006B3D), Color(0xFF00A86B)],
  );

  static LinearGradient lightGradient() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
  );

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryGreen,
      onPrimary: surfaceWhite,
      secondary: accentCoral,
      onSecondary: surfaceWhite,
      error: negative,
      onError: surfaceWhite,
      surface: surfaceWhite,
      onSurface: textDark,
    );

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.merriweather(fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
      displayMedium: GoogleFonts.merriweather(fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
      displaySmall: GoogleFonts.merriweather(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
      headlineLarge: GoogleFonts.merriweather(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
      headlineMedium: GoogleFonts.merriweather(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
      headlineSmall: GoogleFonts.merriweather(fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
      titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
      titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: textDark),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textDark),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: textDark),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: textDark),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal, color: textDark),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textDark),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textDark),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: textDark),
    );

    return ThemeData(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: surfaceWhite,
        elevation: 0,
        titleTextStyle: GoogleFonts.merriweather(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: surfaceWhite,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: elevationResting,
        color: surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(panelRadius),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        filled: true,
        fillColor: surfaceWhite,
      ),
    );
  }
}
