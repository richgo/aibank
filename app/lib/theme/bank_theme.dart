import 'package:flutter/material.dart';

class BankTheme {
  static const positive = Color(0xFF1B8A3A);
  static const negative = Color(0xFFB00020);

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003366)),
        cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12)),
      );
}
