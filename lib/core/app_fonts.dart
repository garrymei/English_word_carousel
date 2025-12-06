import 'package:flutter/material.dart';

class AppFonts {
  static const String primary = 'Orbitron';
  static const String fallbackCn = 'PingFang SC';

  static TextTheme textTheme(BuildContext context) {
    final base = Theme.of(context).textTheme;
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: primary),
      displayMedium: base.displayMedium?.copyWith(fontFamily: primary),
      displaySmall: base.displaySmall?.copyWith(fontFamily: primary),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: primary),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: primary),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: primary),
      titleLarge: base.titleLarge?.copyWith(fontFamily: primary),
      titleMedium: base.titleMedium?.copyWith(fontFamily: primary),
      titleSmall: base.titleSmall?.copyWith(fontFamily: primary),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: primary),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: primary),
      bodySmall: base.bodySmall?.copyWith(fontFamily: primary),
      labelLarge: base.labelLarge?.copyWith(fontFamily: primary),
      labelMedium: base.labelMedium?.copyWith(fontFamily: primary),
      labelSmall: base.labelSmall?.copyWith(fontFamily: primary),
    );
  }
}