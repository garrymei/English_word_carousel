import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}