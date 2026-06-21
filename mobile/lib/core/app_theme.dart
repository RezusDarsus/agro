import 'package:flutter/material.dart';

class AppTheme {
  static const green = Color(0xFF064E34);
  static const cream = Color(0xFFFFFBF0);
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          brightness: Brightness.light,
          surface: cream,
        ),
        scaffoldBackgroundColor: cream,
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: green,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            backgroundColor: green,
            foregroundColor: cream,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      );
}
